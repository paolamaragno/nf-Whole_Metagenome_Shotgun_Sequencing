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
include { BOWTIE2_INDEX_GENOME2 } from './modules/bowtie2_index_genome2'
include { BOWTIE2_SAMTOOLS_ONE_INDEX } from './modules/bowtie2_samtools_one_index'
include { BOWTIE2_SAMTOOLS_TWO_INDEX } from './modules/bowtie2_samtools_two_index'
include { METAPHLAN4 } from './modules/metaphlan4'
include { MERGE_PROFILES_METAPHLAN4 } from './modules/metaphlan4_merge_profiles'
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
			.map{ row -> tuple(row.name, file(row.fastq1), file(row.fastq2), row.genome_for_mapping) }


        TRIMMOMATIC(reads)

	ch_versions = ch_versions.mix(TRIMMOMATIC.out.versions)

	if (params.genome_fasta_2) {

		BOWTIE2_INDEX_GENOME1(params.genome_fasta_1)
	
		ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME1.out.versions)

		BOWTIE2_INDEX_GENOME2(params.genome_fasta_2)

		ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME2.out.versions)
	
		BOWTIE2_SAMTOOLS_TWO_INDEX(BOWTIE2_INDEX_GENOME1.out.genome1_index,BOWTIE2_INDEX_GENOME2.out.genome_index,TRIMMOMATIC.out.trimmomatic_reads,reads)

		ch_versions = ch_versions.mix(BOWTIE2_SAMTOOLS_TWO_INDEX.out.versions)

		METAPHLAN4(BOWTIE2_SAMTOOLS_TWO_INDEX.out.processed_reads)

	        ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	}
	else { 
		BOWTIE2_INDEX_GENOME1(params.genome_fasta_1)

		ch_versions = ch_versions.mix(BOWTIE2_INDEX_GENOME1.out.versions)

		BOWTIE2_SAMTOOLS_ONE_INDEX(BOWTIE2_INDEX_GENOME1.out.genome1_index, TRIMMOMATIC.out.trimmomatic_reads)		

		ch_versions = ch_versions.mix(BOWTIE2_SAMTOOLS_ONE_INDEX.out.versions)

		METAPHLAN4(BOWTIE2_SAMTOOLS_ONE_INDEX.out.processed_reads)

		ch_versions = ch_versions.mix(METAPHLAN4.out.versions)

	}
	
	MERGE_PROFILES_METAPHLAN4(METAPHLAN4.out.profile.collect())

	ch_versions = ch_versions.mix(MERGE_PROFILES_METAPHLAN4.out.versions)

	if (params.genome_fasta_2) {

		HUMANN3(BOWTIE2_SAMTOOLS_TWO_INDEX.out.processed_reads,METAPHLAN4.out.profile)

	}
	else {

		HUMANN3(BOWTIE2_SAMTOOLS_ONE_INDEX.out.processed_reads, METAPHLAN4.out.profile)

	}

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

