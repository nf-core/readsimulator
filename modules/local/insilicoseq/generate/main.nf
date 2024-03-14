process INSILICOSEQ_GENERATE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/insilicoseq:1.6.0--pyh7cba7a3_0':
        'biocontainers/insilicoseq:1.6.0--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fastq.gz*"), emit: fastq
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args          = task.ext.args ?: ''
    def args2         = task.ext.args2 ?: ''
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def seed          = task.ext.seed ?: "${meta.seed}"
    def input_format  = "--${params.metagenome_input_format}"
    if (fasta) {
        def is_compressed = fasta.name.endsWith(".gz")
        def fasta_name    = fasta.name.replace(".gz", "")
        """
        seed=\$(echo $seed | sed 's/\\[//g' | sed 's/\\]//g')
        prefix=\$(echo $prefix | sed 's/\\[//g' | sed 's/\\]//g')

        if [ "${is_compressed}" == "true" ]; then
            gzip -c -d ${fasta} > ${fasta_name}
        fi

        iss generate \\
            ${input_format} ${fasta_name} \\
            --seed \$seed \\
            --output \$prefix \\
            --compress \\
            --cpus $task.cpus \\
            $args

        rm ${fasta_name}

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
