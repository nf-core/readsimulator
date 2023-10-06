process JAPSA_CAPSIM {

    tag "$meta.id"
    label 'process_single'

    container "docker.io/vmurigneux/japsa@sha256:ba74e9c844d115f390be62cde1272cfa5e10492512674ea342a4eeec47840f98"

     // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "CAPSIM does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    input:
    tuple val(meta), path(fasta), path(probes), path(index)

    output:
    tuple val(meta), path("*.fastq.gz*"), emit: fastq
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
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
