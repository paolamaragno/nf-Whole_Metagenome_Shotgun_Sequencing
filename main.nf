#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

log.info """\
    WHOLE METAGENOME SHOTGUN SEQUENCING ANALYSIS
    The pipeline is designed for shotgun sequencing data of microbiome 
    ================================================================
    input_reads	: ${params.input_reads}
    outdir	: ${params.outdir}
    """
    .stripIndent()


include { TRIMMOMATIC } from './modules/trimmomatic'
include { BOWTIE2_INDEX_GENOME1 } from './modules/bowtie2_index_genome1'
include { COPY_INDEX_GENOME1 } from './modules/copy_index_genome1'
include { BOWTIE2_INDEX_GENOME2 } from './modules/bowtie2_index_genome2'
include	{ COPY_INDEX_GENOME2 } from './modules/copy_index_genome2'
include { BOWTIE2_SAMTOOLS_ONE_INDEX } from './modules/bowtie2_samtools_one_index'
include { BOWTIE2_SAMTOOLS_TWO_INDEX } from './modules/bowtie2_samtools_two_index'
include { METAPHLAN_INSTALL } from './modules/metaphlan4_db_install'
include { METAPHLAN4 } from './modules/metaphlan4'
include { MERGE_PROFILES_METAPHLAN4 } from './modules/metaphlan4_merge_profiles'
include { HUMANN_INSTALL_DB_NUCLEOTIDES } from './modules/humann3_install_db_nucleotides'
include { HUMANN_INSTALL_DB_PROTEINS } from './modules/humann3_install_db_proteins'
include { HUMANN_INSTALL_DB_MAPPING_UTIL } from './modules/humann3_install_db_mapping_utility'
include { HUMANN_CHANGE_CONFIG } from './modules/humann3_change_config'
include { HUMANN3 } from './modules/humann3'
include { HUMANN3_POST_PROCESSING } from './modules/humann3_post_processing'
include { PREPARE_GMM_PREDICTION } from './modules/prepare_GMM_prediction'
include { GMM_PREDICTION } from './modules/GMM_prediction'
include { COLLECT_VERSIONS } from './modules/versions'
include { MULTIQC } from './modules/multiqc'

workflow {

	ch_versions = Channel.empty()

        reads = Channel
			.fromPath(params.input_reads)
			.splitCsv(header: true)
			.map{ row -> tuple(row.name, file(row.fastq1), file(row.fastq2), row.host_genome_for_mapping) }


        TRIMMOMATIC(reads)

	ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions)
	
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


	if (params.utility_db) {

		ch_humann_mapping_utility = Channel.value(params.utility_db)

	} else {

		ch_humann_mapping_utility = HUMANN_INSTALL_DB_MAPPING_UTIL().humann_db_utilities
		ch_versions = ch_versions.mix(HUMANN_INSTALL_DB_MAPPING_UTIL.out.versions)

	}

	HUMANN_CHANGE_CONFIG(ch_humann_mapping_utility)

	if (params.genome_fasta_2) {
		
		if (params.genome_index_1) {

			COPY_INDEX_GENOME1(params.genome_index_1)
			
			ch_versions = ch_versions.mix(COPY_INDEX_GENOME1.out.versions)
			
			index_genome1 = COPY_INDEX_GENOME1.out.genome1_index
		}

		else {

			BOWTIE2_INDEX_GENOME1(params.genome_fasta_1)

			ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME1.out.versions)

			index_genome1 =	BOWTIE2_INDEX_GENOME1.out.genome1_index
		}

		if (params.genome_index_2) { 

                        COPY_INDEX_GENOME2(params.genome_index_2)

			ch_versions = ch_versions.mix(COPY_INDEX_GENOME2.out.versions)

			index_genome2 =	COPY_INDEX_GENOME2.out.genome2_index		

                }

                else { 

                        BOWTIE2_INDEX_GENOME2(params.genome_fasta_2)

			ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME2.out.versions)

			index_genome2 = BOWTIE2_INDEX_GENOME2.out.genome2_index

                }


		BOWTIE2_SAMTOOLS_TWO_INDEX(index_genome1,index_genome2,TRIMMOMATIC.out.trimmomatic_reads,reads)

		ch_versions = ch_versions.mix(BOWTIE2_SAMTOOLS_TWO_INDEX.out.versions)

		METAPHLAN4(BOWTIE2_SAMTOOLS_TWO_INDEX.out.processed_reads, ch_metaphlan_db)

	        ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	}
	else { 
		if (params.genome_index_1) {

                        COPY_INDEX_GENOME1(params.genome_index_1)

                        ch_versions = ch_versions.mix(COPY_INDEX_GENOME1.out.versions)

                        index_genome1 = COPY_INDEX_GENOME1.out.genome1_index
                }

                else {

                      	BOWTIE2_INDEX_GENOME1(params.genome_fasta_1)

                        ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME1.out.versions)

                        index_genome1 = BOWTIE2_INDEX_GENOME1.out.genome1_index
                }

		BOWTIE2_SAMTOOLS_ONE_INDEX(index_genome1, TRIMMOMATIC.out.trimmomatic_reads)		

		ch_versions = ch_versions.mix(BOWTIE2_SAMTOOLS_ONE_INDEX.out.versions)

		METAPHLAN4(BOWTIE2_SAMTOOLS_ONE_INDEX.out.processed_reads, ch_metaphlan_db)

		ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	}
	
	MERGE_PROFILES_METAPHLAN4(METAPHLAN4.out.profile.collect())

	ch_versions = ch_versions.mix(MERGE_PROFILES_METAPHLAN4.out.versions)

	HUMANN3(METAPHLAN4.out.processed_fastq,METAPHLAN4.out.profile, ch_humann_nucleo, ch_humann_proteins)

	ch_versions = ch_versions.mix(HUMANN3.out.versions)

	HUMANN3_POST_PROCESSING(HUMANN3.out.genefamilies_KO_not_renamed.collect(), HUMANN3.out.genefamilies_KO_renamed.collect(), HUMANN3.out.pathabundance.collect())

	ch_versions = ch_versions.mix(HUMANN3_POST_PROCESSING.out.versions)

	PREPARE_GMM_PREDICTION(HUMANN3_POST_PROCESSING.out.all_genefamilies_KO_not_renamed)

	ch_versions = ch_versions.mix(PREPARE_GMM_PREDICTION.out.versions)

	GMM_PREDICTION(PREPARE_GMM_PREDICTION.out.all_genefamilies_KO_for_omixer)	

	ch_versions = ch_versions.mix(GMM_PREDICTION.out.versions)

	COLLECT_VERSIONS(ch_versions.unique().collectFile(name: 'collated_versions.yml'))

	MULTIQC(COLLECT_VERSIONS.out.mqc_yml.collect())
}

