process PBSIM {

    tag "$meta.id"
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "bioconda::pbsim=1.0.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbsim:1.0.3--h4ac6f70_7':
        'biocontainers/pbsim:1.0.3--h4ac6f70_7' }"

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
    def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    pbsim \\
        --prefix $prefix \\
        --seed $seed \\
        $args \\
        $fasta

    gzip ${prefix}.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbsim: $VERSION
    END_VERSIONS
    """
}
