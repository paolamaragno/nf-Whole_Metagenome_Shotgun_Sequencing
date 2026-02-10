// Helper function to display help message

def helpMessage() {

    log.info"""

    WHOLE METAGENOME SHOTGUN SEQUENCING ANALYSIS
    The pipeline is designed for the analysis of Whole Metagenome Shotgun data from Illumina sequencing 

    For samples CSV, three columns named "sample", "fastq1" and "fastq2" are required. 

    All the parameters must be specified in the nextflow.config configuration file. Then, you can run the pipeline 
    with the following command:

    nextflow run main.nf -c nextflow.config -profile <desired profile> --input samples.csv 

    Command line arguments:
    
    -profile			Configuration profile to use. Available: docker, singularity, apptainer, conda
    -bg				To run the pipeline in background
    -resume			To resume the previous execution of the pipeline

    The following parameters must be specified in nextflow.config file or directly in nextflow command line (in this 
    second case the value specified in nextflow.config will be overwritten):
    --input_reads		Path to the comma-separated sample file
    --outdir			Path to a folder where to store results 
    --genome_fasta		Path to the genome fasta file 
    --genome_index		Path to the folder containing the index of the genome (default: false, in this case 
				the indexing of the genome will be done by the pipeline)
    --idx_genome		Name to use for the the index of the genome
    --metaphlan_db		Path to the folder containing Metaphlan database (default: false, in this case the 
				database will be downloaded by the pipeline)
    --metaphlan_db_index	Desired version for metaphlan database 
    --humann_nucleotide_db	Path to the folder containing Humann nucleotide database (default: false, in this case 
				the database will be downloaded by the pipeline)
    --humann_protein_db		Path to the folder containing Humann protein database (default: false, in this case 
				the database will be downloaded by the pipeline)
    --gene_families_db		Specification of the version of Uniref database for gene family definitions 
				(default: "uniref90")
    --regroup_option		Specification of the functional category in which regrouping gene families
				(default: "uniref90_ko")
    --rename_option		Specification of the feature type in which rename gene families 
				(default: "kegg-orthology")
    --save_reference		Choose whether saving or not the downloaded reference databases (default: true)

    """
}

process write_log {

    publishDir = [
                path: {"${params.outdir}" },
                mode: 'copy'
        ]
   
    cpus = { 1 }
    memory { 1.GB }

    input:
    val(logs)

    output:
    path "parameters.txt"

    script:
    """
    echo '$logs' > parameters.txt
    """
}

// Function to validate input parameters

def validateParameters() {

    if (!params.input_reads) {
        exit 1, "Input file not specified!"
    }
    if (!params.outdir) {
        exit 1, "Output directory not specified!"
    }

}

// Function to print pipeline header

def printHeader() {

    log.info"""
    WHOLE METAGENOME SHOTGUN SEQUENCING ANALYSIS
    The pipeline is designed for the analysis of Whole Metagenome Shotgun data from Illumina sequencing
    ================================================================
    input_reads : ${params.input_reads}
    outdir      : ${params.outdir}
    """
    .stripIndent()
}

def printComplete() {

   if (workflow.success) {
    log.info """
    ====================================================
    ✅ The pipeline was executed successfully! ✅
    All results were saved in: ${params.outdir}
    Total execution time: ${workflow.duration}
    ====================================================
    """.stripIndent()
        }
}
