process CRABS_DBDOWNLOAD {

    tag ""
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "bioconda::crabs=0.1.1-0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/crabs:0.1.1--pyhb7b1952_0':
        'swordfish/crabs:0.1.4' }" // this container works better than biocontainers/crabs:0.1.1--pyhb7b1952_0
                                   // no it doesn't, it just gives me a different error message

    input:

    output:
    path("*.fasta")     , emit: fasta
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def VERSION = '0.1.1' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    crabs db_download \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        crabs: $VERSION
    END_VERSIONS
    """
}
