//
// Simulate amplicon reads
//

include { CRABS_DBIMPORT    } from '../../modules/local/crabs_dbimport'
include { CRABS_INSILICOPCR } from '../../modules/local/crabs_insilicopcr'
include { ART_ILLUMINA      } from '../../modules/nf-core/art/illumina/main'
include { PBSIM             } from '../../modules/local/pbsim'
include { SIMLORD           } from '../../modules/local/simlord'

workflow AMPLICON {
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
    ch_art_input = CRABS_INSILICOPCR.out.fasta
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
            ch_art_input,
            "HS25",
            130
        )
        ch_versions = ch_versions.mix(ART_ILLUMINA.out.versions.first())
        ch_illumina_reads = ART_ILLUMINA.out.fastq
    }

    // Pacbio simulators,
    // PBSIM is expecting a file that's not in the container, maybe it can be pulled?
    // SIMLORD works, but doesn't have a seed parameter, maybe it's using the internal clock for the seed?
    //PBSIM (
    //    ch_art_input
    //)
    //SIMLORD (
    //    ch_art_input
    //)

    // Nanopore simulator
    //NANOSIM ()

    // BAD READ simulator
    //BADREAD ()

    emit:
    illumina_reads = ch_illumina_reads // channel: [ meta, fastq ]
    versions       = ch_versions       // channel: [ versions.yml ]
}
