process WGSIM {
    tag "$meta.id"
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wgsim:1.0--he4a0461_7':
        'biocontainers/wgsim:1.0--he4a0461_7' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fq.gz*"), emit: fastq
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def seed          = task.ext.seed ?: "${meta.seed}"
    def VERSION       = '1.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    seed=\$(echo $seed | sed 's/\\[//g' | sed 's/\\]//g')
    prefix=\$(echo $prefix | sed 's/\\[//g' | sed 's/\\]//g')

    wgsim \\
        $args \\
        -S \$seed \\
        $fasta \\
        \${prefix}_R1.fq \\
        \${prefix}_R2.fq

    gzip \${prefix}_R1.fq \${prefix}_R2.fq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wgsim: $VERSION
    END_VERSIONS
    """
}
