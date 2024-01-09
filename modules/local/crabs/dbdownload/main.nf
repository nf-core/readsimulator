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
    def args       = task.ext.args ?: ''
    def input_args = amplicon_ncbi_db ? "--source ncbi --database ${params.amplicon_ncbi_db} --output ncbi.fa" :
        amplicon_embl_db ? "--source embl --database ${params.amplicon_embl_db} --output embl.fa " :
        amplicon_bold_db ? "--source bold --database ${params.amplicon_bold_db} --output bold.fa" :
        ""

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
