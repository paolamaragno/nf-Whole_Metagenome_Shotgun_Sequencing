#!/bin/sh

process HUMANN3 {

	cpus = 7
	memory = 26.GB
	
	//tag "Humann3 on $sample_id"	
	publishDir "${params.outdir}/humann_out", mode: 'copy', saveAs: { filename -> filename.equals('versions_humann.yml') ? null : filename }

	container 'humann3.9_modified_latest.sif'

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
	"""
	humann -i ${processed_fastq} --output . --search-mode ${params.gene_families_db} --threads ${task.cpus} \
               --taxonomic-profile ${profile} --protein-database ${humann_db_proteins} --nucleotide-database ${humann_db_nucleo}

	humann_regroup_table -i ${sample_id}_filtered.final_R1_R2_genefamilies.tsv -o ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --groups ${params.regroup_option}
        humann_rename_table --input ${sample_id}_filtered.final_R1_R2_genefamilies_KO_not_renamed.tsv --output ${sample_id}_filtered.final_R1_R2_genefamilies_KO_renamed.tsv --names ${params.rename_option}

	cat <<-END_VERSIONS > versions_humann.yml
        "${task.process}":
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
