# nf-Whole_Metagenome_Shotgun_Sequencing
Nextflow pipeline to perform bioinformatic analysis of Whole Metagenome Shotgun Sequencing.

This pipeline exploits the BioBakery tools developed for microbial community profiling (https://github.com/biobakery).

# Getting started
* [Nextflow](https://nf-co.re/docs/usage/installation)
* [Docker](https://www.docker.com/)
* [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html)
* [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)

# Overview
<img width="1221" alt="image" src="https://github.com/user-attachments/assets/15bd1314-f8a7-4307-9fe7-8fc400bdebec" />

# Usage
First, it is advised to perform a quality check on your fastq files running 
```
fastqc *fastq.gz -o ./fastqc_result
mutiqc ./fastqc_result
```
Particularly, check the Sequence Length Distribution to set the correct minimum read length paramenter for Trimmomatic and Metaphlan.

Preparare the sample.csv file with the following structure:
```
name,fastq1,fastq2,host_genome_for_mapping
sample_name1,path/to/sample_name1_R1.fastq,path/to/sample_name1_R2.fastq,genome1
sample_name2,path/to/sample_name2_R1.fastq,path/to/sample_name2_R2.fastq,genome2
```

The last column, host_genome_for_mapping, is used to specify the genome of the host organism (e.g. human, mouse). If all the samples come from the same host, the host genome will be always genome1 and so all the samples will be mapped (during BOWTIE2_SAMTOOLS_ONE_INDEX process) against the same host genome to remove contaminations. If some samples come from a different host, the host genome for these samples will be genome2 and so the samples will be mapped (during BOWTIE2_SAMTOOLS_TWO_INDEX) against the right host genome (genome1 or genome2) to remove contaminations.

All the parameters must be specified in the nextflow.conf configuration file. Then, you can run the pipeline with the following command:
```
nextflow run main.nf -c nextflow.config -w /path/to/work_directory 
```

All the containers are already saved in a directory that is downloaded together with all the code, but Singularity must be installed together with Nextflow.

# Workflow description
1. [Trimmomatic](http://www.usadellab.org/cms/index.php?page=trimmomatic) for quality control and adapter trimming 
1. [Bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml) and [Samtools](https://www.htslib.org/) for alignment to the reference genome of the host and removal of contaminations
1. Merge forward and reverse fastq files using **cat**
1. [Metaphlan](https://github.com/biobakery/MetaPhlAn)
   1. Taxonomic profiling at sample level
   1. **merge_metaphlan_tables.py** to merge profiles from all the samples in a single file
1. [Humann](https://github.com/biobakery/Humann)
   1. Fuctional characterization at sample level
    1. **humann_regoup_table** to group Uniref90 terms in KO ids
    1. **humann_rename_table** to rename KO ids in human-readable descriptions
    1. **humann_join_tables** to merge profiles from all the samples in a single file
1. [omixer](https://github.com/raeslab/omixer-rpm) for the prediction of Gut Metabolic Modules (GMM)
1. [multiqc](https://github.com/MultiQC/MultiQC) to print a html report reporting the version of all the softwares used during the pipeline. 
