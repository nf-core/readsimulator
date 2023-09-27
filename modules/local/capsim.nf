process CAPSIM {

    tag "$meta.id"
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    //conda "bioconda::crabs=0.1.1-0"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/crabs:0.1.1--pyhb7b1952_0':
    //    'docker.io/vmurigneux/japsa' }"
    container "docker.io/vmurigneux/japsa"

    input:
    tuple val(meta), path(fasta), path(probes), path(index)

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
    def VERSION = '0.9-01a' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    jsa.sim.capsim \\
        --reference ${fasta} \\
        --probe ${probes} \\
        --ID ${prefix} \\
        --seed ${seed} \\
        ${args2} ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        capsim: $VERSION
    END_VERSIONS
    """
}
