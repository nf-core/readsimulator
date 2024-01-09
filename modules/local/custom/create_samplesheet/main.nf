process CREATE_SAMPLESHEET {
    tag "$meta.id"

    input:
    tuple val(meta), path(fastq)

    output:
    tuple val(meta), path("*.csv"), emit: samplesheet

    exec:
    def fastq_1 = "${params.outdir}/${meta.outdir}/${fastq}"
    def fastq_2 = ''
    if (fastq instanceof List && fastq.size() == 2) {
        fastq_1 = "${params.outdir}/${meta.outdir}/${fastq[0]}"
        fastq_2 = "${params.outdir}/${meta.outdir}/${fastq[1]}"
    }

    // Add relevant fields to the beginning of the map
    pipeline_map = [
        sample  : "${meta.id}",
        fastq_1 : fastq_1,
        fastq_2 : fastq_2
    ]

    // Create a samplesheet
    samplesheet  = pipeline_map.keySet().collect{ '"' + it + '"'}.join(",") + '\n'
    samplesheet += pipeline_map.values().collect{ '"' + it + '"'}.join(",")

    // Write samplesheet to file
    def samplesheet_file  = task.workDir.resolve("${meta.datatype}_${meta.id}.samplesheet.csv")
    samplesheet_file.text = samplesheet
}
