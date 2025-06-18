#!/bin/sh

process HUMANN3_POST_PROCESSING {
	
	cpus = 1
	memory = 5.GB

	publishDir "${params.outdir}/humann_out", mode: 'copy', saveAs: { filename -> filename.equals('versions_humann.yml') ? null : filename }

	container 'humann3.9_modified_latest.sif'

	input:
	path(genefamilies_KO_not_renamed)
	path(genefamilies_KO_renamed)
	path(pathabundance)

	output:
	path("all_genefamilies_KO_not_renamed.tsv"), emit: all_genefamilies_KO_not_renamed
	path("all_genefamilies_KO_renamed.tsv")
	path("all_pathabundance.tsv")
	path  "versions_humann.yml", emit: versions

	script:
	"""
	mkdir -p all_genefamilies_KO_not_renamed
	cp ${genefamilies_KO_not_renamed} all_genefamilies_KO_not_renamed

	mkdir -p all_pathabundance
	cp ${pathabundance} all_pathabundance

	mkdir -p all_genefamilies_KO_renamed
	cp ${genefamilies_KO_renamed} all_genefamilies_KO_renamed

	humann_join_tables --input all_genefamilies_KO_not_renamed --output all_genefamilies_KO_not_renamed.tsv --file_name genefamilies_KO_not_renamed

	humann_join_tables --input all_pathabundance --output all_pathabundance.tsv --file_name pathabundance

	humann_join_tables --input all_genefamilies_KO_renamed --output all_genefamilies_KO_renamed.tsv --file_name genefamilies_KO_renamed

	cat <<-END_VERSIONS > versions_humann.yml
        "${task.process}":
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS

	"""
}
