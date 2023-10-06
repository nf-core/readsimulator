//
// Simulate UCE target capture reads
//

include { BOWTIE2_BUILD                   } from '../../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN                   } from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX                  } from '../../modules/nf-core/samtools/index/main'
include { JAPSA_CAPSIM as CAPSIM_ILLUMINA } from '../../modules/local/japsa_capsim'
include { JAPSA_CAPSIM as CAPSIM_PACBIO   } from '../../modules/local/japsa_capsim'
include { UNZIP                           } from '../../modules/local/unzip'

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
                def meta = [:]
                meta.id = "target_capture"
                return [ meta, fasta ]
        }

    //
    // MODULE: Create Bowtie index
    //
    BOWTIE2_BUILD (
        ch_meta_fasta
    )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    //
    // MODULE: Unzip probes file if user is downloading them
    //
    if ( !params.probe_fasta ) {
        ch_zip_file = Channel.fromPath(params.probe_ref_db[params.probe_ref_name]["url"])
        ch_probes = UNZIP (
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
    // MODULE: Simulate target capture illumina reads
    //
    ch_illumina_reads = Channel.empty()
    CAPSIM_ILLUMINA (
        ch_capsim_input
    )
    ch_versions = ch_versions.mix(CAPSIM_ILLUMINA.out.versions.first())
    ch_illumina_reads = CAPSIM_ILLUMINA.out.fastq
        .map {
            meta, fastqs ->
                meta.outdir = "capsim_illumina"
                meta.datatype = "target_capture_illumina"
                return [ meta, fastqs ]
        }

    //
    // MODULE: Simulate target capture pacbio reads
    //
    ch_pacbio_reads = Channel.empty()
    if ( params.target_capture_pacbio ) {
        CAPSIM_PACBIO (
            ch_capsim_input
        )
        ch_versions = ch_versions.mix(CAPSIM_PACBIO.out.versions.first())
        ch_pacbio_reads = CAPSIM_PACBIO.out.fastq
            .map {
                meta, fastqs ->
                    meta.outdir   = "capsim_pacbio"
                    meta.datatype = "target_capture_pacbio"
                    return [ meta, fastqs ]
            }
    }

    emit:
    illumina_reads = ch_illumina_reads // channel: [ meta, fastq ]
    pacbio_reads   = ch_pacbio_reads   // channel: [ meta, fastq ]
    versions       = ch_versions       // channel: [ versions.yml ]
}
