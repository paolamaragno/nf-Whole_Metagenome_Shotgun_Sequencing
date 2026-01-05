#!/bin/sh

process METAPHLAN_INSTALL {

	cpus = { 2 + (1 * (task.attempt-1)) }
    memory = { 2.GB + (2.GB * (task.attempt-1)) }

	if( params.run_mode == 'conda' ) {
		conda 'metaphlan=4.1.1'
    } else {
		container 'biocontainers/metaphlan:4.1.1--pyhdfd78af_0'
    }

	publishDir = [
		path: { "${params.outdir}/references" },
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_metaphlan.yml")) { return null }
                        else { return fn } }
	]

	output:
	path "metaphlan_db", emit: metaphlan_db
	path "versions_metaphlan.yml", emit: versions

	script:
	"""
	mkdir metaphlan_db

	metaphlan --install --bowtie2db metaphlan_db --index ${params.metaphlan_db_index}

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}": 
            methaphlan: \$(echo \$(metaphlan --version) | sed 's/^.*MetaPhlAn version //; s/Using.*\$//')
            metaphlan_database_version: "${params.metaphlan_db_index}"
	END_VERSIONS
	"""
}
