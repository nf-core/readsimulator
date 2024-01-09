process JAPSA_CAPSIM {
    tag "$meta.id"
    label 'process_single'

    container "nf-core/japsa:0"

    input:
    tuple val(meta), path(fasta), path(probes), path(index)

    output:
    tuple val(meta), path("*.fastq.gz*"), emit: fastq
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "CAPSIM does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args    = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def seed    = task.ext.seed ?: "${meta.seed}"
    """
    jsa.sim.capsim \\
        --reference ${fasta} \\
        --probe ${probes} \\
        --ID ${prefix} \\
        --seed ${seed} \\
        ${args} ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        capsim: \$(jsa | tail -n +2 | head -n 1 | awk -F, '{print \$1}') | sed 's/Version //g'
    END_VERSIONS
    """
}
