/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                      } from '../../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../../modules/nf-core/multiqc/main'
include { paramsSummaryMap            } from 'plugin/nf-validation'
include { paramsSummaryMultiqc        } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML      } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText      } from '../../subworkflows/local/utils_nfcore_readsimulator_pipeline'
include { INSILICOSEQ_GENERATE        } from '../../modules/local/insilicoseq/generate/main'       // TODO: Add module to nf-core/modules
include { CREATE_SAMPLESHEET          } from '../../modules/local/custom/create_samplesheet/main'
include { MERGE_SAMPLESHEETS          } from '../../modules/local/custom/merge_samplesheets/main'
include { WGSIM                       } from '../../modules/local/wgsim/main'                      // TODO: Add module to nf-core/modules
include { AMPLICON_WORKFLOW           } from '../../subworkflows/local/amplicon_workflow'
include { TARGET_CAPTURE_WORKFLOW     } from '../../subworkflows/local/target_capture_workflow'
include { NCBIGENOMEDOWNLOAD          } from '../../modules/nf-core/ncbigenomedownload/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow READSIMULATOR {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions        = Channel.empty()
    ch_multiqc_files   = Channel.empty()
    ch_simulated_reads = Channel.empty()
    ch_taxids          = Channel.empty()
    ch_accessions      = Channel.empty()

    if ( params.fasta ) {
        ch_fasta = Channel.fromPath(params.fasta)
    } else {
        if ( params.ncbidownload_accessions ) {
            ch_accessions = Channel.fromPath(params.ncbidownload_accessions)
        } else if ( params.ncbidownload_taxids ) {
            ch_taxids = Channel.fromPath(params.ncbidownload_taxids)
        }

        //
        // MODULE: Download reference fasta files
        //
        NCBIGENOMEDOWNLOAD (
            [ id:"ncbigenomedownload" ],
            ch_accessions.ifEmpty([]),
            ch_taxids.ifEmpty([]),
            params.ncbidownload_group
        )

        //
        // MODULE: Combine FASTA files
        //
        MERGE_FASTAS (
            NCBIGENOMEDOWNLOAD.out.fna
        )

        ch_fasta = MERGE_FASTAS.out.fasta
            .map {
                meta, fasta ->
                return fasta
            }
    }

    if ( params.probe_file ) {
        ch_probes = Channel.fromPath(params.probe_file)
    } else {
        ch_probes = Channel.empty()
    }

    //
    // SUBWORKFLOW: Simulate amplicon reads
    //
    if ( params.amplicon ) {
        AMPLICON_WORKFLOW (
            ch_fasta.ifEmpty([]),
            ch_samplesheet
        )
        ch_versions        = ch_versions.mix(AMPLICON_WORKFLOW.out.versions.first())
        ch_simulated_reads = ch_simulated_reads.mix(AMPLICON_WORKFLOW.out.reads)
    }

    //
    // SUBWORKFLOW: Simulate UCE target capture reads
    //
    if ( params.target_capture ) {
        TARGET_CAPTURE_WORKFLOW (
            ch_fasta,
            ch_samplesheet,
            ch_probes.ifEmpty([])
        )
        ch_versions        = ch_versions.mix(TARGET_CAPTURE_WORKFLOW.out.versions.first())
        ch_simulated_reads = ch_simulated_reads.mix(TARGET_CAPTURE_WORKFLOW.out.reads)
    }

    //
    // MODULE: Simulate metagenomic reads
    //
    if ( params.metagenome ) {
        INSILICOSEQ_GENERATE (
            ch_samplesheet.combine(ch_fasta.ifEmpty([[]]))
        )
        ch_versions         = ch_versions.mix(INSILICOSEQ_GENERATE.out.versions.first())
        ch_metagenome_reads = INSILICOSEQ_GENERATE.out.fastq
            .map {
                meta, fastqs ->
                    meta.outdir   = "insilicoseq"
                    meta.datatype = "metagenomic_illumina"
                    return [ meta, fastqs ]
            }
        ch_simulated_reads  = ch_simulated_reads.mix(ch_metagenome_reads)
    }

    //
    // MODULE: Simulate wholegenomic reads
    //
    if ( params.wholegenome ) {
        WGSIM (
            ch_input.combine(ch_fasta)
        )
        ch_versions          = ch_versions.mix(WGSIM.out.versions.first())
        ch_wholegenome_reads = WGSIM.out.fastq
            .map {
                meta, fastqs ->
                    meta.outdir   = "wgsim"
                    meta.datatype = "wholegenome"
                    return [ meta, fastqs ]
            }
        ch_simulated_reads  = ch_simulated_reads.mix(ch_wholegenome_reads)
    }

    // MODULE: Create sample sheet (just the header and one row)
    CREATE_SAMPLESHEET (
        ch_simulated_reads
    )

    // Group the samplesheets by datatype so that we can merge them
    ch_samplesheets = CREATE_SAMPLESHEET.out.samplesheet
        .map {
            meta, samplesheet ->
                tuple( meta.datatype, meta, samplesheet )
        }
        .groupTuple(sort: 'deep')
        .map {
            datatype, old_meta, samplesheet ->
                def meta = [:]
                meta.id  = datatype
                return [ meta, samplesheet ]
        }

    // MODULE: Merge the samplesheets by data type
    ch_final_samplesheet = MERGE_SAMPLESHEETS (
        ch_samplesheets
    )

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_simulated_reads
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    simulated_reads = ch_simulated_reads
    samplesheet     = ch_final_samplesheet
    multiqc_report  = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions        = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

workflow.onError {
    if (workflow.errorReport.contains("Process requirement exceeds available memory")) {
        println("🛑 Default resources exceed availability 🛑 ")
        println("💡 See here on how to configure pipeline: https://nf-co.re/docs/usage/configuration#tuning-workflow-resources 💡")
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
