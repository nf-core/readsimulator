process SIMLORD {

    tag "$meta.id"
    label 'process_single'

    conda "bioconda::simlord=1.0.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/simlord:1.0.4--py310h4b81fae_3':
        'biocontainers/simlord:1.0.4--py310h4b81fae_3' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: fastq
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def seed    = task.ext.seed ?: "${meta.seed}"
    """
    simlord \\
        --read-reference $fasta \\
        $args \\
        $prefix

    gzip ${prefix}.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbsim: \$(simlord --version)
    END_VERSIONS
    """
}
