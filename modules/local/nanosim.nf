process NANOSIM {

    tag "$meta.id"
    label 'process_single'

    conda "bioconda::nanosim=3.1.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanosim:3.1.0--hdfd78af_0':
        'biocontainers/nanosim:3.1.0--hdfd78af_0' }"

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
    read_analysis.py metagenome \\
        --read ${fasta} \\
        --probe ${probes} \\
        --ID ${prefix} \\
        --seed ${seed} \\
        ${args2} ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanosim: \$(read_analysis.py --version)
    END_VERSIONS
    """
}
