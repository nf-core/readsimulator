//
// Simulate UCE target capture reads
//

include { BOWTIE2_BUILD             } from '../../modules/nf-core/bowtie2/build/main'
include { BOWTIE2_ALIGN             } from '../../modules/nf-core/bowtie2/align/main'
include { SAMTOOLS_INDEX            } from '../../modules/nf-core/samtools/index/main'
include { CAPSIM as CAPSIM_ILLUMINA } from '../../modules/local/capsim'
include { CAPSIM as CAPSIM_PACBIO   } from '../../modules/local/capsim'

workflow TARGET_CAPTURE {
    take:
    ch_fasta  // file: /path/to/reference.fasta
    ch_input  // channel: [ meta ]
    ch_probes // file: /path/to/probes.fasta

    main:
    ch_versions = Channel.empty()

    // Add a meta map to fasta channel for compatibility with modules
    ch_meta_fasta = ch_fasta
        .map {
            fasta ->
                def meta = [:]
                meta.id = "illumina_uce"
                return [ meta, fasta ]
        }

    //
    // MODULE: Create Bowtie index
    //
    BOWTIE2_BUILD (
        ch_meta_fasta
    )
    ch_versions = ch_versions.mix(BOWTIE2_BUILD.out.versions.first())

    ch_probes = ch_probes
        .map {
            meta, fasta ->
                meta.single_end = true
                return [ meta, fasta ]
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
        //.map {
        //    meta, fasta, bam, index ->
        //        meta.id = "illumina_taget_capture_" + meta.id
        //        return [ meta, fasta, bam, index ]
        //}

    //
    // MODULE: Simulate target capture illumina reads
    //
    ch_illumina_reads = Channel.empty()
    if ( params.illumina ) {
        CAPSIM_ILLUMINA (
            ch_capsim_input
        )
        ch_versions = ch_versions.mix(CAPSIM_ILLUMINA.out.versions.first())
        ch_illumina_reads = CAPSIM_ILLUMINA.out.fastq
    }

    //
    // MODULE: Simulate target capture pacbio reads
    //
    ch_pacbio_reads = Channel.empty()
    if ( params.pacbio ) {
        CAPSIM_PACBIO (
            ch_capsim_input
        )
        ch_versions = ch_versions.mix(CAPSIM_PACBIO.out.versions.first())
        ch_pacbio_reads = CAPSIM_PACBIO.out.fastq
    }

    emit:
    illumina_reads = ch_illumina_reads // channel: [ meta, fastq ]
    pacbio_reads   = ch_pacbio_reads // channel: [ meta, fastq ]
    versions       = ch_versions       // channel: [ versions.yml ]
}
