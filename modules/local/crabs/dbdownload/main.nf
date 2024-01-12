process CRABS_DBDOWNLOAD {

    tag ""
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/crabs:0.1.1--pyhb7b1952_0':
        'biocontainers/crabs:0.1.1--pyhb7b1952_0' }"

    input:
    val amplicon_ncbi_db
    val amplicon_embl_db
    val amplicon_bold_db

    output:
    path("*.fasta")     , emit: fasta
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def ncbi_input  = amplicon_ncbi_db ? "--source ncbi --database ${amplicon_ncbi_db} --output ncbi.fasta" : ""
    def embl_input = amplicon_embl_db ? "--source embl --database ${params.amplicon_embl_db} --output embl.fasta " : ""
    def bold_input = amplicon_bold_db ? "--source bold --database ${params.amplicon_bold_db} --output bold.fasta" : ""
    def input_args = ncbi_input + embl_input + bold_input
    def VERSION = '0.1.1' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    crabs db_download \\
        $args \\
        $input_args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        crabs: $VERSION
    END_VERSIONS
    """
}
