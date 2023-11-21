//
// Simulate UCE target capture reads
//

include { BOWTIE2_BUILD                   } from '../../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN                   } from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX                  } from '../../modules/nf-core/samtools/index/main'
include { JAPSA_CAPSIM                    } from '../../modules/local/japsa_capsim'
include { UNZIP as UNZIP_PROBE            } from '../../modules/local/unzip'

workflow TARGET_CAPTURE_WORKFLOW {
    take:
    ch_fasta  // file: /path/to/reference.fasta
    ch_input  // channel: [ meta ]
    ch_probes // file: /path/to/probes.fasta

    main:
    ch_versions = Channel.empty()

    ch_meta_fasta = ch_fasta
        .map {
            fasta ->
                return [ [id:"target_capture"], fasta ]
        }

    //
    // MODULE: Create Bowtie index
    //
    BOWTIE2_BUILD (
        ch_meta_fasta
    )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    //
    // MODULE: Unzip probes file if user is downloading a reference probe file
    //
    if ( !params.probe_fasta ) {
        ch_zip_file = Channel.fromPath(params.probe_ref_db[params.probe_ref_name]["url"])
        ch_probes = UNZIP_PROBE (
            ch_zip_file
        ).file
    }
    ch_probes = ch_probes
        .map {
            fasta ->
                def meta = [:]
                meta.id = "probes"
                meta.single_end = true
                [ meta, fasta ]
        }

    //
    // MODULE: Align probes to genome
    //
    BOWTIE2_ALIGN (
        ch_probes,
        BOWTIE2_BUILD.out.index,
        false,
        false
    )
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions.first())

    //
    // MODULES: Get SAM index
    //
    SAMTOOLS_INDEX (
        BOWTIE2_ALIGN.out.aligned
    )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    // Now that we have our fasta file + BAM file + index,
    // we need to map them to our sample data
    ch_capsim_input = ch_meta_fasta.map { it = it[1] }
        .combine ( BOWTIE2_ALIGN.out.aligned.map { it = it[1] } )
        .combine ( SAMTOOLS_INDEX.out.bai.map { it = it[1] } )
        .combine ( ch_input )
        .map {
            it = [ it[3], it[0], it[1], it[2] ]
        }

    //
    // MODULE: Simulate target capture reads
    //
    ch_reads = Channel.empty()
    JAPSA_CAPSIM (
        ch_capsim_input
    )
    ch_versions = ch_versions.mix(JAPSA_CAPSIM.out.versions.first())
    ch_reads    = JAPSA_CAPSIM.out.fastq
        .map {
            meta, fastqs ->
                meta.outdir   = "capsim"
                meta.datatype = "target_capture"
                return [ meta, fastqs ]
        }

    emit:
    reads    = ch_reads    // channel: [ meta, fastq ]
    versions = ch_versions // channel: [ versions.yml ]
}
