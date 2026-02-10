#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

log_text = """
    Parameters set for the pipeline
    =========================================================
    Path to the genome fasta file: $params.genome_fasta
    Specification whether the input fastq file has been obtained by the merging of forward and reverse reads: $params.merged_paired_fastq
    Path to the folder containing the index of the genome: $params.genome_index
    Name to use for the the index of the genome: $params.idx_genome
    Path to the folder containing Metaphlan database: $params.metaphlan_db
    Desired version for metaphlan database: $params.metaphlan_db_index
    Path to the folder containing Humann nucleotide database: $params.humann_nucleotide_db
    Path to the folder containing Humann protein database: $params.humann_protein_db
    Specification of the version of Uniref database for gene family definitions: $params.gene_families_db
    Specification of the functional category in which regrouping gene families:	$params.regroup_option
    Specification of the feature type in which rename gene families: $params.rename_option
    Choose whether saving or not the genome index and/or the downloaded reference databases: $params.save_reference
    Version of Nextflow pipeline: $params.version
"""

include { helpMessage; write_log; validateParameters; printHeader; printComplete } from './modules/utils'
include { SPLIT_PAIRED_FASTQ } from './modules/split_paired_fastq'
include { FASTQC_RAW_READS } from './modules/fastqc_raw_reads'
include { MULTIQC_RAW_READS } from './modules/multiqc_raw_reads'
include { GET_GLOBAL_MIN_LENGTH } from './modules/get_global_min_length'
include { FASTP } from './modules/fastp'
include { BUILD_GENOME_INDEX } from './modules/build_genome_index'
include { COPY_GENOME_INDEX } from './modules/copy_genome_index'
include { REMOVE_HOST_READS } from './modules/remove_host_reads'
include { FASTQC_FILTERED_READS } from './modules/fastqc_filtered_reads'
include { MULTIQC_FILTERED_READS } from './modules/multiqc_filtered_reads'
include { METAPHLAN_INSTALL } from './modules/metaphlan/metaphlan4_db_install'
include { METAPHLAN4 } from './modules/metaphlan/metaphlan4'
include { METAPHLAN4_MERGE_PROFILES } from './modules/metaphlan/metaphlan4_merge_profiles'
include { HUMANN_INSTALL_UTILITY_MAPPING } from './modules/humann/humann3_install_utility_mapping'
include { HUMANN_INSTALL_DB_NUCLEOTIDES } from './modules/humann/humann3_install_db_nucleotides'
include { HUMANN_INSTALL_DB_PROTEINS } from './modules/humann/humann3_install_db_proteins'
include { HUMANN3 } from './modules/humann/humann3'
include { HUMANN3_POST_PROCESSING } from './modules/humann/humann3_post_processing'
include { COLLECT_VERSIONS } from './modules/versions'
include { MULTIQC_FINAL } from './modules/multiqc_final'

if (params.help) exit 0, helpMessage()

workflow {

	printHeader()

	validateParameters()

	log.info(log_text)

	write_log(log_text)

	ch_versions = Channel.empty()

	reads = Channel
		.fromPath(params.input_reads)
		.splitCsv(header: true)
		.map { row ->
		if (params.merged_paired_fastq) {
	
			return tuple(row.sample, file(row.merged_fastq))
	
		} else {
		
			return tuple(row.sample, [file(row.fastq1), file(row.fastq2)])
		
		}	
	}

	if (params.merged_paired_fastq) {

		SPLIT_PAIRED_FASTQ(reads)
		ch_versions = ch_versions.mix(SPLIT_PAIRED_FASTQ.out.versions)
		
		FASTQC_RAW_READS(SPLIT_PAIRED_FASTQ.out.splitted_fastq)
	
	} else {

		FASTQC_RAW_READS(reads)

	}

	ch_versions = ch_versions.mix(FASTQC_RAW_READS.out.versions)

	MULTIQC_RAW_READS(FASTQC_RAW_READS.out.fastqc_raw_out.collect())

	ch_versions = ch_versions.mix(MULTIQC_RAW_READS.out.versions)

	min_length_ch = GET_GLOBAL_MIN_LENGTH(MULTIQC_RAW_READS.out.data_dir)


	if (params.merged_paired_fastq) {

		FASTP(SPLIT_PAIRED_FASTQ.out.splitted_fastq, min_length_ch)

	} else {

		FASTP(reads, min_length_ch)

	}
	
	ch_versions = ch_versions.mix(FASTP.out.versions)

	if (params.metaphlan_db) {

		ch_metaphlan_db = Channel.value(params.metaphlan_db)

	} else {
	
		ch_metaphlan_db	= METAPHLAN_INSTALL().metaphlan_db
		ch_versions = ch_versions.mix(METAPHLAN_INSTALL.out.versions)	

	}

	if (params.humann_protein_db) { 

                ch_humann_proteins = Channel.value(params.humann_protein_db)

	} else { 

                ch_humann_proteins = HUMANN_INSTALL_DB_PROTEINS().humann_db_proteins
                ch_versions = ch_versions.mix(HUMANN_INSTALL_DB_PROTEINS.out.versions)          

	}

	if (params.humann_nucleotide_db) {

                ch_humann_nucleo = Channel.value(params.humann_nucleotide_db)

	} else {

                ch_humann_nucleo = HUMANN_INSTALL_DB_NUCLEOTIDES().humann_db_nucleo
                ch_versions = ch_versions.mix(HUMANN_INSTALL_DB_NUCLEOTIDES.out.versions)

	}

	if (params.genome_index) {

		COPY_GENOME_INDEX(params.genome_index)

		ch_versions = ch_versions.mix(COPY_GENOME_INDEX.out.versions)

                index_genome = COPY_GENOME_INDEX.out.genome_index
           
	} else {

		BUILD_GENOME_INDEX(params.genome_fasta)

                ch_versions = ch_versions.mix(BUILD_GENOME_INDEX.out.versions)

                index_genome = BUILD_GENOME_INDEX.out.genome_index

	}

	REMOVE_HOST_READS(index_genome, FASTP.out.fastp_reads)

	ch_versions = ch_versions.mix(REMOVE_HOST_READS.out.versions)

	FASTQC_FILTERED_READS(REMOVE_HOST_READS.out.processed_reads)

	ch_versions = ch_versions.mix(FASTQC_FILTERED_READS.out.versions)

	MULTIQC_FILTERED_READS(FASTQC_FILTERED_READS.out.fastqc_filtered_out.collect())

	ch_versions = ch_versions.mix(MULTIQC_FILTERED_READS.out.versions)

	METAPHLAN4(REMOVE_HOST_READS.out.processed_reads, ch_metaphlan_db, min_length_ch)

	ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	METAPHLAN4_MERGE_PROFILES(METAPHLAN4.out.profile.collect())

	ch_versions = ch_versions.mix(METAPHLAN4_MERGE_PROFILES.out.versions)

	humann_utility_mapping_ch  = Channel.value([])

	if (params.run_mode == 'conda') {

		humann_utility_mapping_ch = HUMANN_INSTALL_UTILITY_MAPPING().humann_utility_mapping
		
		ch_versions = ch_versions.mix(HUMANN_INSTALL_UTILITY_MAPPING.out.versions)
 
	} 
	
	HUMANN3(METAPHLAN4.out.processed_fastq, METAPHLAN4.out.profile, humann_utility_mapping_ch, ch_humann_nucleo, ch_humann_proteins)  
	
	ch_versions = ch_versions.mix(HUMANN3.out.versions)

	HUMANN3_POST_PROCESSING(HUMANN3.out.genefamilies_KO_renamed.collect(), HUMANN3.out.pathabundance.collect())
        
	ch_versions = ch_versions.mix(HUMANN3_POST_PROCESSING.out.versions)

	COLLECT_VERSIONS(ch_versions.unique().collectFile(name: 'collated_versions.yml'))

	MULTIQC_FINAL(COLLECT_VERSIONS.out.mqc_yml.collect())

	printComplete()

}
