#!/bin/sh

process HUMANN3_WITH_METAPHLAN {

	cpus { 10 + (2 * (task.attempt -1)) }
	memory { 100.GB + (10.GB * (task.attempt -1)) }
	time '48h'

	tag "Humann3 on $sample_id"

	if( params.run_mode == 'conda' ) {
                conda 'biobakery::humann=3.9 bioconda::metaphlan=4.1.1 python=3.7'
        } else {
		container 'pmaragno/humann_3.9_updated:latest'
        }

	input:
	tuple val(sample_id), path(processed_fastq)
	path(metaphlan_db)
	path(humann_utility_mapping)
	path(humann_db_nucleo)
	path(humann_db_proteins)

	output:
	path("${sample_id}_filtered.final_R1_R2_humann_temp/${sample_id}_filtered.final_R1_R2_metaphlan_bugs_list.tsv"), emit: metaphlan_output
	path("${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv"), emit: genefamilies_KO_renamed
	path("${sample_id}_filtered.final_R1_R2_genefamilies_EC_renamed.tsv"), emit: genefamilies_EC_renamed
	path("${sample_id}_filtered.final_R1_R2_pathabundance.tsv"), emit: pathabundance
	path("${sample_id}_filtered.final_R1_R2_pathcoverage.tsv"), emit: pathcoverage
	path("${sample_id}_filtered.final_R1_R2_genefamilies.tsv"), emit: genefamilies 
	path  "versions_humann.yml", emit: versions

	script:
	def run_regroup_uniref_ko = params.regroup_uniref90_to_ko ? "humann_regroup_table -i ${sample_id}_filtered.final_R1_R2_genefamilies.tsv -o ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --groups uniref90_ko" : ""
        def run_rename_ko = params.rename_ko ? "humann_rename_table --input ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --output ${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv --names kegg-orthology" : ""
        def regroup_uniref_ec = params.regroup_uniref90_to_ec ? "humann_regroup_table -i ${sample_id}_filtered.final_R1_R2_genefamilies.tsv -o ${sample_id}_filtered.final_R1_R2_genefamilies_EC_not_renamed.tsv --groups uniref90_level4ec" : ""
        def run_rename_ec = params.rename_ec ? "humann_rename_table --input ${sample_id}_filtered.final_R1_R2_genefamilies_EC_not_renamed.tsv --output ${sample_id}_filtered.final_R1_R2_genefamilies_EC_renamed.tsv --names ec" : ""

        if (params.run_mode == 'conda') {
		"""
		humann_config --update database_folders utility_mapping ${humann_utility_mapping}

		humann -i ${processed_fastq} --output . --search-mode uniref90 --threads ${task.cpus} --protein-database ${humann_db_proteins} --nucleotide-database ${humann_db_nucleo} --bowtie-options "--very-sensitive --seed 1234" --diamond-options "--block-size 0.5 --index-chunks 6  --top 1" \
				--metaphlan-options "--index mpa_vJun23_CHOCOPhlAnSGB_202403 --bowtie2db ${metaphlan_db} --read_min_len 100 "

		${run_regroup_uniref_ko}

		${run_rename_ko}

		${regroup_uniref_ec}

		${run_rename_ec}

		cat <<-END_VERSIONS > versions_humann.yml
	        "${task.process}":
	            humann: \$(echo \$(humann --version | sed 's/^.*humann //; s/Using.*\$//'))
	            metaphlan: \$(echo \$(metaphlan --version | sed 's/^.*MetaPhlAn version //; s/Using.*\$//'))
	            metaphlan_database_version: "mpa_vJun23_CHOCOPhlAnSGB_202403"
	            diamond: \$(echo \$(diamond --version | sed 's/^.*diamond version //; s/Using.*\$//'))
	            bowtie2: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
		END_VERSIONS
                """
        } else {
		"""
		humann -i ${processed_fastq} --output . --search-mode uniref90 --threads ${task.cpus} --protein-database ${humann_db_proteins} --nucleotide-database ${humann_db_nucleo} --bowtie-options "--very-sensitive --seed 1234" --diamond-options "--block-size 0.5 --index-chunks 6 --top 1" \
				--metaphlan-options "--index mpa_vJun23_CHOCOPhlAnSGB_202403 --bowtie2db ${metaphlan_db} --read_min_len 100"

		${run_regroup_uniref_ko}

                ${run_rename_ko}

                ${regroup_uniref_ec}

		${run_rename_ec}

		cat <<-END_VERSIONS > versions_humann.yml
	        "${task.process}":
	            humann: \$(echo \$(humann --version | sed 's/^.*humann //; s/Using.*\$//'))
	            metaphlan: \$(echo \$(metaphlan --version | sed 's/^.*MetaPhlAn version //; s/Using.*\$//'))
	            metaphlan_database_version: "mpa_vJun23_CHOCOPhlAnSGB_202403"
	            diamond: \$(echo \$(diamond --version | sed 's/^.*diamond version //; s/Using.*\$//'))
	            bowtie2: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
		END_VERSIONS
		"""
        }
}
