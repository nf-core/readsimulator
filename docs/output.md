# nf-core/readsimulator: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [ART](#art) - Simulated amplicon reads
- [bedtools](#bedtools) - Probe fasta file
- [Bowtie2](#bowtie2) - Alignments and index files
- [CapSim](#capsim) - Simulated target capture reads
- [CRABS](#crabs) - Reference database formatted for amplicon read simulation
- [FastQC](#fastqc) - Raw read QC
- [InSilicoSeq](#insilicoseq) - Simulated metagenomic reads
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [ncbi-genome-download](#ncbi-genome-download) - Reference fasta files
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution
- [Samplesheet](#samplesheet) - Samplesheets produced during the running of the pipeline
- [Unzip](#unzip) - Unziped probe file
- [Wgsim](#wgsim) - Simulated wholegenome reads

### ART

<details markdown="1">
<summary>Output files</summary>

- `art_illumina/`
  - `*1.fq.gz`: Read 1 files simulating Illumina reads. The prefix will be the sample name found in the samplesheet.
  - `*2.fq.gz`: Read 2 files simulating Illumina reads. The prefix will be the sample name found in the samplesheet.

</details>

[ART](https://www.niehs.nih.gov/research/resources/software/biostatistics/art/index.cfm) is a tool for simulating Illumina sequencing reads. For further reading and documentation see the [ART Illumina manual](https://manpages.debian.org/testing/art-nextgen-simulation-tools/art_illumina.1.en.html).

### bedtools

<details markdown="1">
<summary>Output files</summary>

- `bedtools/`
  - `*.fa`: The probe fasta file extracted from the reference fasta file if the input probe file was a bed file.

</details>

[bedtools](https://pubmed.ncbi.nlm.nih.gov/20110278/) is a suite of tools for genomic data analysis. For further reading and documentation see the [bedtools documentation](https://bedtools.readthedocs.io/en/latest/).

### Bowtie2

<details markdown="1">
<summary>Output files</summary>

- `bowtie2/`
  - `bowtie2/`
    - `*.bt2`: Bowtie2 index files.
  - `*.bam`: BAM file produced from aligning with Bowtie2.
  - `*.bowtie2.log`: Log file containing alignment information.
  - `*.bai`: Index file produced with SAMtools.

</details>

[Bowtie2](https://www.nature.com/articles/nmeth.1923) is a popular tool for aligning sequences to reference reads. For further reading and documentation see the [Bowtie2 manual](https://bowtie-bio.sourceforge.net/bowtie2/manual.shtml).
[SAMtools](https://academic.oup.com/gigascience/article/10/2/giab008/6137722?login=false) is a popular set of tools for working with sequencing data. For further reading and documentation see the [SAMtools documentation](http://www.htslib.org/doc/).

### CapSim

<details markdown="1">
<summary>Output files</summary>

- `capsim_illumina/`
  - `*_1.fastq.gz`: Read 1 files simulating Illumina reads. The prefix will be the sample name found in the samplesheet.
  - `*_2.fastq.gz`: Read 2 files simulating Illumina reads. The prefix will be the sample name found in the samplesheet.
- `capsim_pacbio/`
  - `*_1.fastq.gz`: Read 1 files simulating PacBio reads. The prefix will be the sample name found in the samplesheet.
  - `*_1.fastq.gz`: Read 2 files simulating PacBio reads. The prefix will be the sample name found in the samplesheet.

</details>

[CapSim](https://academic.oup.com/bioinformatics/article/34/5/873/4575140) is a tool to simulate capture sequencing reads. It's part of the [Japsa package](https://japsa.readthedocs.io/en/latest/). For further reading and documentation see the [CapSim documentation](https://japsa.readthedocs.io/en/latest/tools/jsa.sim.capsim.html).

### CRABS

<details markdown="1">
<summary>Output files</summary>

- `crabs_dbimport/`
  - `*.fa`: Reference fasta file.
- `crabs_insilicopcr/`
  - `*.fa`: Reference fasta file for simulating amplicon data.

</details>

[CRABS](https://onlinelibrary.wiley.com/doi/10.1111/1755-0998.13741) is a toolfor reformating reference databases for simulating amplicon sequencing data. For further reading and documentation see the [CRABS repo](https://github.com/gjeunen/reference_database_creator).

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

![MultiQC - FastQC sequence counts plot](images/mqc_fastqc_counts.png)

![MultiQC - FastQC mean quality scores plot](images/mqc_fastqc_quality.png)

![MultiQC - FastQC adapter content plot](images/mqc_fastqc_adapter.png)

:::note
The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.
:::

### ncbi-genome-download

<details markdown="1">
<summary>Output files</summary>

- `ncbigenomedownload/`
  - `*.fna.gz`: Reference fasta files downloaded from NCBI

</details>

[ncbi-genome-download](https://github.com/kblin/ncbi-genome-download) downloads reference genome files from NCBI.

### InSilicoSeq

<details markdown="1">
<summary>Output files</summary>

- `insilicoseq/`
  - `*R1.fastq.gz`: Read 1 files simulating Illumina metagenomic reads. The prefix will be the sample name found in the samplesheet.
  - `*R2.fastq.gz`: Read 2 files simulating Illumina metagenomic reads. The prefix will be the sample name found in the samplesheet.

</details>

[InSilicoSeq](https://academic.oup.com/bioinformatics/article/35/3/521/5055123) is a tool for simulating Illumina metagenomic sequencing reads. For further reading and documentation see the [InSilicoSeq documentation](https://insilicoseq.readthedocs.io/en/latest/).

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

### Samplesheet

<details markdown="1">
<summary>Output files</summary>

- `samplesheet/`
  - `*.csv`: Samplesheets with all samples.
- `samplesheet_individual_samples/`
  - `*.csv`: Samplesheets for each individual sample.

</details>

### Unzip

<details markdown="1">
<summary>Output files</summary>

- `probes/`
  - `unziped/`
    - `*.fasta`: Probe file downloaded if custom probe hasn't been provided with `--probe_fasta` parameter.

</details>

### Wgsim

<details markdown="1">
<summary>Output files</summary>

- `wgsim/`
  - `*R1.fq.gz`: Read 1 files simulating wholegenome reads. The prefix will be the sample name found in the samplesheet.
  - `*R2.fq.gz`: Read 2 files simulating wholegenome reads. The prefix will be the sample name found in the samplesheet.

</details>

[Wgsim](https://github.com/lh3/wgsim) is a tool for simulating wholegenome sequencing reads. For further reading and documentation see the [Wgsim manual](<https://www.venea.net/man/wgsim(1)>).
