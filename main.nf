#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

log.info """\
    WHOLE METAGENOME SHOTGUN SEQUENCING ANALYSIS
    The pipeline is designed for the analysis of Whole Metagenome Shotgun data from Illumina sequencing 
    ================================================================
    input_reads	: ${params.input_reads}
    outdir	: ${params.outdir}
    """
    .stripIndent()

include { FASTP } from './modules/fastp'
include { BUILD_GENOME_INDEX } from './modules/build_genome_index'
include { COPY_GENOME_INDEX } from './modules/copy_genome_index'
include { REMOVE_HOST_READS } from './modules/remove_host_reads'
include { METAPHLAN_INSTALL } from './modules/metaphlan/metaphlan4_db_install'
include { METAPHLAN4 } from './modules/metaphlan/metaphlan4'
include { METAPHLAN4_MERGE_PROFILES } from './modules/metaphlan/metaphlan4_merge_profiles'
include { HUMANN_INSTALL_UTILITY_MAPPING } from './modules/humann/humann3_install_utility_mapping'
include { HUMANN_INSTALL_DB_NUCLEOTIDES } from './modules/humann/humann3_install_db_nucleotides'
include { HUMANN_INSTALL_DB_PROTEINS } from './modules/humann/humann3_install_db_proteins'
include { HUMANN3 } from './modules/humann/humann3'
include { HUMANN3_POST_PROCESSING } from './modules/humann/humann3_post_processing'
include { PREPARE_GMM_PREDICTION } from './modules/prepare_GMM_prediction'
include { GMM_PREDICTION } from './modules/GMM_prediction'
include { COLLECT_VERSIONS } from './modules/versions'
include { MULTIQC } from './modules/multiqc'

workflow {

	ch_versions = Channel.empty()

        reads = Channel
			.fromPath(params.input_reads, followLinks: true)
			.splitCsv(header: true)
			.map { row -> tuple(row.name, file(row.fastq1), file(row.fastq2)) }

	FASTP(reads)

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

	if (params.human_nucleotide_db) {

                ch_humann_nucleo = Channel.value(params.human_nucleotide_db)

        } else {

                ch_humann_nucleo = HUMANN_INSTALL_DB_NUCLEOTIDES().humann_db_nucleo
                ch_versions = ch_versions.mix(HUMANN_INSTALL_DB_NUCLEOTIDES.out.versions)

        }

	if (params.genome_index) {

		COPY_GENOME_INDEX(params.genome_index)

		ch_versions = ch_versions.mix(COPY_GENOME_INDEX.out.versions)

                index_genome = COPY_GENOME_INDEX.out.genome_index
           
	}

        else {

		BUILD_GENOME_INDEX(params.genome_fasta)

                ch_versions = ch_versions.mix(BUILD_GENOME_INDEX.out.versions)

                index_genome = BUILD_GENOME_INDEX.out.genome_index

        }

	REMOVE_HOST_READS(index_genome, FASTP.out.fastp_reads)

	ch_versions = ch_versions.mix(REMOVE_HOST_READS.out.versions)

	METAPHLAN4(REMOVE_HOST_READS.out.processed_reads, ch_metaphlan_db)

	ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	METAPHLAN4_MERGE_PROFILES(METAPHLAN4.out.profile.collect())

	ch_versions = ch_versions.mix(METAPHLAN4_MERGE_PROFILES.out.versions)

	if (params.run_mode == 'conda') {

		humann_utility_mapping = HUMANN_INSTALL_UTILITY_MAPPING.out.humann_utility_mapping
		
		ch_versions = ch_versions.mix(HUMANN_INSTALL_UTILITY_MAPPING.out.versions)
 
		HUMANN3(METAPHLAN4.out.processed_fastq, METAPHLAN4.out.profile, humann_utility_mapping, ch_humann_nucleo, ch_humann_proteins)  

	} else {
	
		HUMANN3(METAPHLAN4.out.processed_fastq, METAPHLAN4.out.profile, ch_humann_nucleo, ch_humann_proteins)
	}
	
	ch_versions = ch_versions.mix(HUMANN3.out.versions)

	HUMANN3_POST_PROCESSING(HUMANN3.out.genefamilies_KO_not_renamed.collect(), HUMANN3.out.genefamilies_KO_renamed.collect(), HUMANN3.out.pathabundance.collect())
        
	ch_versions = ch_versions.mix(HUMANN3_POST_PROCESSING.out.versions)

	PREPARE_GMM_PREDICTION(HUMANN3_POST_PROCESSING.out.all_genefamilies_KO_not_renamed, params.R_prepare_GMM_prediction)

	ch_versions = ch_versions.mix(PREPARE_GMM_PREDICTION.out.versions)

	GMM_PREDICTION(PREPARE_GMM_PREDICTION.out.all_genefamilies_KO_for_omixer, params.omixer_jar, params.GMM_db)	

	ch_versions = ch_versions.mix(GMM_PREDICTION.out.versions)

	COLLECT_VERSIONS(ch_versions.unique().collectFile(name: 'collated_versions.yml'))

	MULTIQC(COLLECT_VERSIONS.out.mqc_yml.collect())

}

workflow.onComplete {
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
