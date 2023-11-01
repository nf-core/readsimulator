process MERGE_SAMPLESHEETS {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(samplesheet)

    output:
    tuple val(meta), path("*.csv"), emit: samplesheet

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    """
    echo \\"sample\\",\\"fastq_1\\",\\"fastq_2\\" > "${prefix}_samplesheet.csv"
    for curr_sheet in $samplesheet; do
        tail -n +2 "\$curr_sheet" >> "${prefix}_samplesheet.csv"
        echo >> "${prefix}_samplesheet.csv"
    done
    """
}
