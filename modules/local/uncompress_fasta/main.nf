process UNCOMPRESS_FASTA {
    tag "$file"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gzip:1.11':
        'biocontainers/gzip:1.11' }"

    input:
    path(fasta)

    output:
    path "${fasta.name.replace('.gz', '')}", emit: fasta
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def is_compressed = fasta.name.endsWith(".gz")
    def fasta_name    = fasta.name.replace(".gz", "")
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(gzip -V | head -n 1 | sed 's/gzip //g')
    END_VERSIONS
    """
}
