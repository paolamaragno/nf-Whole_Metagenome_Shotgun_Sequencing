# nf-Whole_Metagenome_Shotgun_Sequencing
Nextflow pipeline to perform bioinformatic analysis of Whole Metagenome Shotgun Sequencing data.

This pipeline exploits the BioBakery tools developed for microbial community profiling (https://github.com/biobakery).

# Getting started
* [Nextflow](https://nf-co.re/docs/usage/installation)
* [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html)
* [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)

# Overview

<img width="839" alt="image" src="https://github.com/user-attachments/assets/38c3c2a9-9102-4aa1-9c72-ed7434a957e3" />

# Usage
First, it is advised to perform a quality check on your fastq files running 
```
fastqc *fastq.gz -o ./fastqc_result
mutiqc ./fastqc_result
```
Particularly, check the Sequence Length Distribution in order to set the correct minimum read length paramenter for Trimmomatic and Metaphlan.

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
