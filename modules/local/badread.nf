process BADREAD {

    tag "$meta.id"
    label 'process_single'

    conda "bioconda::badread=0.4.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/badread:0.4.0--pyhdfd78af_1':
        'biocontainers/badread:0.4.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fastq.gz*"), emit: fastq
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def args2   = task.ext.args2 ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def seed    = task.ext.seed ?: "${meta.seed}"
    """
    badread simulate \\
        --reference ${fasta} \\
        --seed ${seed} \\
        --quantity 50x

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        badread: \$(badread simulate --version)
    END_VERSIONS
    """
}
