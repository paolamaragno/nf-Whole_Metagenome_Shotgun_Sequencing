#!/bin/sh

process HUMANN3 {

	cpus = { 8 + (1 * (task.attempt-1)) }
	memory = { 25.GB + (2.GB * (task.attempt-1)) }
	
	tag "Humann3 on $sample_id"	

	if( params.run_mode == 'conda' ) {
		conda 'biobakery::humann=3.9 metaphlan=4.1.1 python=3.7'
        }

        if( params.run_mode == 'container' ) {
		container 'pmaragno/humann_3.9_updated:latest'
        }

	input:
	tuple val(sample_id), path(processed_fastq)
	path(profile)
	path(humann_db_nucleo)
	path(humann_db_proteins)
	
	output:
	path("${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv"), emit: genefamilies_KO_not_renamed
	path("${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv"), emit: genefamilies_KO_renamed
	path("${sample_id}_filtered.final_R1_R2_pathabundance.tsv"), emit: pathabundance
	path("${sample_id}_filtered.final_R1_R2_pathcoverage.tsv"), emit: pathcoverage
	path("${sample_id}_filtered.final_R1_R2_genefamilies.tsv"), emit: genefamilies 
	path  "versions_humann.yml", emit: versions

	script:
	if (params.run_mode == 'conda') {
		"""
		humann_config --update database_folders utility_mapping /rg/ivd-meinel/pmaragno/nextflow/data/utility_mapping		

		humann -i ${processed_fastq} --output . --search-mode ${params.gene_families_db} --threads ${task.cpus} --taxonomic-profile ${profile} --protein-database ${humann_db_proteins} --nucleotide-database ${humann_db_nucleo} --bowtie-options "--very-sensitive --seed 1234"  

		humann_regroup_table -i ${sample_id}_filtered.final_R1_R2_genefamilies.tsv -o ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --groups ${params.regroup_option}
		humann_rename_table --input ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --output ${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv --names ${params.rename_option}

		cat <<-END_VERSIONS > versions_humann.yml
	        "${task.process}":
	            humann: \$(echo \$(humann --version | sed 's/^.*humann //; s/Using.*\$//'))
	            methaphlan: \$(echo \$(metaphlan --version | sed 's/^.*MetaPhlAn version //; s/Using.*\$//'))
	            diamond: \$(echo \$(diamond --version | sed 's/^.*diamond version //; s/Using.*\$//'))
	            bowtie2: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
		END_VERSIONS
		"""
	} else {
		"""
		humann -i ${processed_fastq} --output . --search-mode ${params.gene_families_db} --threads ${task.cpus} --taxonomic-profile ${profile} --protein-database ${humann_db_proteins} --nucleotide-database ${humann_db_nucleo} --bowtie-options "--very-sensitive --seed 1234"  
		
		humann_regroup_table -i ${sample_id}_filtered.final_R1_R2_genefamilies.tsv -o ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --groups ${params.regroup_option}
                humann_rename_table --input ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --output ${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv --names ${params.rename_option}

		cat <<-END_VERSIONS > versions_humann.yml
	        "${task.process}":
	            humann: \$(echo \$(humann --version | sed 's/^.*humann //; s/Using.*\$//'))
	            methaphlan: \$(echo \$(metaphlan --version | sed 's/^.*MetaPhlAn version //; s/Using.*\$//'))
	            diamond: \$(echo \$(diamond --version | sed 's/^.*diamond version //; s/Using.*\$//'))
	            bowtie2: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
		END_VERSIONS
		"""
	}	

}
