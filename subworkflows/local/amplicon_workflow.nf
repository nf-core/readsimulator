//
// Simulate amplicon reads
//

include { CRABS_DBIMPORT    } from '../../modules/local/crabs_dbimport'
include { CRABS_INSILICOPCR } from '../../modules/local/crabs_insilicopcr'
include { ART_ILLUMINA      } from '../../modules/nf-core/art/illumina/main'
include { PBSIM             } from '../../modules/local/pbsim'
include { SIMLORD           } from '../../modules/local/simlord'
include { BADREAD           } from '../../modules/local/badread'
include { NANOSIM           } from '../../modules/local/nanosim'

workflow AMPLICON_WORKFLOW {
    ch_versions = Channel.empty()

    take:
    ch_fasta // file: /path/to/reference.fasta
    ch_input // channel: [ meta ]

    main:
    // Add a meta map to fasta channel for compatibility with modules
    ch_meta_fasta = ch_fasta
        .map {
            fasta ->
                def meta = [:]
                meta.id = "illumina_amplicon"
                return [ meta, fasta ]
        }

    //
    // MODULE: Run Crabs db_import
    //
    CRABS_DBIMPORT (
        ch_meta_fasta
    )
    ch_versions = ch_versions.mix(CRABS_DBIMPORT.out.versions.first())

    //
    // MODULE: Run Crabs insilico_pcr
    //
    CRABS_INSILICOPCR (
        CRABS_DBIMPORT.out.fasta
    )
    ch_versions = ch_versions.mix(CRABS_INSILICOPCR.out.versions.first())

    // Now that we have processed our fasta file,
    // we need to map it to our sample data
    ch_meta_fasta = CRABS_INSILICOPCR.out.fasta
        .combine ( ch_input )
        .map {
            it = [ it[2], it[1] ]
        }
        //.map {
        //    meta, fasta ->
        //        meta.id = "illumina_amplicon_" + meta.id
        //        return [ meta, fasta ]
        //}

    //
    // MODULE: Simulate Illumina reads
    //
    ch_illumina_reads = Channel.empty()
    if ( params.illumina ) {
        ART_ILLUMINA (
            ch_meta_fasta,
            "HS25",
            130
        )
        ch_versions = ch_versions.mix(ART_ILLUMINA.out.versions.first())
        ch_illumina_reads = ART_ILLUMINA.out.fastq
    }

    //
    // MODULE: Simulate pacbio reads
    //
    ch_pacbio_reads = Channel.empty()
    if ( params.pacbio ) {
        ch_model = Channel.fromPath(params.pbsim_model)
        PBSIM (
            ch_meta_fasta,
            ch_model.first()
        )
        ch_versions = ch_versions.mix(PBSIM.out.versions.first())
        ch_pacbio_reads = PBSIM.out.fastq
        //SIMLORD (
        //    ch_meta_fasta
        //)
        //ch_pacbio_reads = SIMLORD.out.fastq
    }

    //BADREAD (
    //    ch_meta_fasta
    //)

    //NANOSIM (
    //    ch_meta_fasta
    //)

    emit:
    illumina_reads = ch_illumina_reads // channel: [ meta, fastq ]
    pacbio_reads   = ch_pacbio_reads   // channel: [ meta, fastq ]
    versions       = ch_versions       // channel: [ versions.yml ]
}
