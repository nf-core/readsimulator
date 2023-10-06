process UNZIP {

    tag "$file"
    label 'process_single'

    conda "conda-forge::unzip=6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/unzip:6.0':
        'biocontainers/unzip:6.0' }"

    input:
    path(file)

    output:
    path "unziped/*"   , emit: file
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir unziped
    unzip ${file} -d unziped

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unzip: \$(unzip -v | head -n 1 | sed 's/UnZip //g' | cut -d ' ' -f1)
    END_VERSIONS
    """
}
