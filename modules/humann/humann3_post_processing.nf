#!/bin/sh

process HUMANN3_POST_PROCESSING {

	cpus = { 1 * task.attempt }
	memory = { 5.GB * task.attempt }

	publishDir = [
		path: { "${params.outdir}/humann3.9" },
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_humann.yml")) { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda 'biobakery::humann=3.9 metaphlan=4.1.1 python=3.7'
	} else {
		container 'biocontainers/humann:3.9--py312hdfd78af_0'
	}

	input:
	path(genefamilies_KO_renamed)
	path(pathabundance)

	output:
	path("all_genefamilies_KO_renamed.tsv")
	path("all_pathabundance.tsv")
	path  "versions_humann.yml", emit: versions

	script:
	"""
	mkdir -p all_pathabundance
	cp ${pathabundance} all_pathabundance

	mkdir -p all_genefamilies_KO_renamed
	cp ${genefamilies_KO_renamed} all_genefamilies_KO_renamed

	humann_join_tables --input all_pathabundance --output all_pathabundance.tsv --file_name pathabundance

	humann_join_tables --input all_genefamilies_KO_renamed --output all_genefamilies_KO_renamed.tsv --file_name genefamilies_KO_renamed

	cat <<-END_VERSIONS > versions_humann.yml
        "${task.process}":
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS

	"""
}
