#!/bin/sh

process METAPHLAN4_MERGE_PROFILES {

	cpus = { 2 + (1 * (task.attempt-1)) }
	memory = { 2.GB + (2.GB * (task.attempt-1)) }

	publishDir = [
		path: { "${params.outdir}/metaphlan4.1.1/" },
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_metaphlan.yml")) { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda "metaphlan=4.1.1"
    } else {
		container 'biocontainers/metaphlan:4.1.1--pyhdfd78af_0'
    }

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
            methaphlan: \$(echo \$(metaphlan --version) | sed 's/^.*MetaPhlAn version //; s/Using.*\$//')
	END_VERSIONS
	"""
}
