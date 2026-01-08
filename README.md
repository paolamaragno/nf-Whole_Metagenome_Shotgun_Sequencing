# nf-Whole_Metagenome_Shotgun_Sequencing
Nextflow pipeline to perform bioinformatic analysis of Whole Metagenome Shotgun Sequencing data.

This pipeline exploits the BioBakery tools developed for microbial community profiling (https://github.com/biobakery).

# Getting started
* [Nextflow](https://www.nextflow.io/docs/latest/index.html)
* [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html)
* [Docker](https://www.docker.com/)
* [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html)
* [Apptainer](https://apptainer.org/)

# Overview
<img width="5604" height="3376" alt="pipeline_flowchart" src="https://github.com/user-attachments/assets/c7e3599c-6589-44f9-8bab-3f098ed19ea5" />

# Usage
First, it is advised to perform a quality check on your fastq files running:
```
fastqc *fastq.gz -o ./fastqc_result
multiqc ./fastqc_result
```
Particularly, check the Sequence Length Distribution to set the correct minimum read length paramenter for Fastp and Metaphlan.

Preparare the sample.csv file with the following structure:
```
name,fastq1,fastq2
sample_name1,path/to/sample_name1_R1.fastq,path/to/sample_name1_R2.fastq
sample_name2,path/to/sample_name2_R1.fastq,path/to/sample_name2_R2.fastq
```

All the parameters must be specified in the nextflow.config configuration file. Then, you can run the pipeline with the following command:
```
nextflow run main.nf -c nextflow.config -profile <desired profile> 

Command line arguments:
-profile                                                 Configuration profile to use. Available: docker, singularity, apptainer, conda
-bg                                                      To run the pipeline in background
-resume                                                  To resume the previous execution of the pipeline

The following parameters must be specified in nextflow.config file or directly in nextflow command line (in this second case the value specified in nextflow.config will be overwritten):
--input_reads                                            Path to the comma-separated sample file
--outdir                                                 Path to a folder where to store results
--genome_fasta                                           Path to the genome fasta file
--genome_index                                           Path to the folder containing the index of the genome (default: false, in this case the indexing of the genome will be done by the pipeline)
--idx_genome                                             Name to use for the the index of the genome
--fastp_MINLEN                                           Minimum required read length
--metaphlan_db                                           Path to the folder containing Metaphlan database (default: false, in this case the database will be downloaded by the pipeline)
--metaphlan_db_index                                     Desired version for metaphlan database
--metaphlan_read_min_len                                 Minimum read length expected by metaphlan (should be the same value of fastp_MINLEN parameter)
--humann_nucleotide_db                                   Path to the folder containing Humann nucleotide database (default: false, in this case the database will be downloaded by the pipeline)
--humann_protein_db                                      Path to the folder containing Humann protein database (default: false, in this case the database will be downloaded by the pipeline)
--gene_families_db                                       Specification of the version of Uniref database for gene family definitions (default: "uniref90")
--regroup_option                                         Specification of the functional category in which regrouping gene families (default: "uniref90_ko")
--rename_option                                          Specification of the feature type in which rename gene families (default: "kegg-orthology")
--save_reference                                         Choose whether saving or not the downloaded reference databases (default: true)

The following are parameters that the user is not advised to change:
--R_prepare_GMM_prediction                               Path to the R file that prepares the input for omixer
--omixer_jar                                             Path to omixer excecutable   
--GMM_db                                                 Path to the GMMs jar file for inferring modules
```

# Workflow description
1. [fastp](https://github.com/OpenGene/fastp) for quality control and adapter trimming 
1. [Bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml) and [Samtools](https://www.htslib.org/) for alignment to the reference genome of the host and removal of contaminations
1. Merge forward and reverse fastq files using **cat**
1. [fastqc](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and [multiqc](https://github.com/MultiQC/MultiQC) for quality control of filtered reads
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
