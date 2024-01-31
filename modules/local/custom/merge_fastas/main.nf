process MERGE_FASTAS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fa.gz"), emit: fasta
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    """
    cat ${args} *.gz > ${prefix}.fa.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(cat --version | head -n 1 | sed 's/cat (GNU coreutils) //g')
    END_VERSIONS
    """
}
