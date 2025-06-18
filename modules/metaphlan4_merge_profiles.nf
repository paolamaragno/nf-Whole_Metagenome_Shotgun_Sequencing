#!/bin/sh

process MERGE_PROFILES_METAPHLAN4 {

	cpus = 7
	memory = 2.GB

	publishDir "${params.outdir}/metaphlan/", mode: 'copy', saveAs: { filename -> filename.equals('versions_metaphlan.yml') ? null : filename }

	container 'metaphlan4.1.1_latest.sif'

	input:
	path(profile)

	output:
	path('merged_abundance_table.txt'), emit: merged_profiles
	path  "versions_metaphlan.yml", emit: versions

	script:
	"""
	merge_metaphlan_tables.py ${profile} > merged_abundance_table.txt

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}":
            metaphlan: \$(echo \$(metaphlan -v) | sed 's/^.*metaphlan //; s/Using.*\$//')
	END_VERSIONS
	"""
}
