process INSILICOSEQ_GENERATE {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::insilicoseq=1.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/insilicoseq:1.6.0--pyh7cba7a3_0':
        'biocontainers/insilicoseq:1.6.0--pyh7cba7a3_0' }"

    input:
    path(fasta)
    val(meta)

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
    if (fasta) {
        """
        seed=\$(echo $seed | sed 's/\\[//g' | sed 's/\\]//g')
        prefix=\$(echo $prefix | sed 's/\\[//g' | sed 's/\\]//g')

        iss generate \\
            --genomes $fasta \\
            --seed \$seed \\
            --output \$prefix \\
            --compress \\
            --cpus $task.cpus \\
            $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            insilicoseq: \$(iss --version | sed 's/iss version //g')
        END_VERSIONS
        """
    } else {
        """
        seed=\$(echo $seed | sed 's/\\[//g' | sed 's/\\]//g')
        prefix=\$(echo $prefix | sed 's/\\[//g' | sed 's/\\]//g')

        iss generate \\
            --ncbi $args2 \\
            --seed \$seed \\
            --output \$prefix \\
            --compress \\
            --cpus $task.cpus \\
            $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            insilicoseq: \$(iss --version | sed 's/iss version //g')
        END_VERSIONS
        """
    }
}
