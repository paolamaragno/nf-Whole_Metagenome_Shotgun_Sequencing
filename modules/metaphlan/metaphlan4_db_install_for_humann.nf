#!/bin/sh

process METAPHLAN_INSTALL_FOR_HUMANN {

	cpus { 4 + (2 * (task.attempt -1 )) }
	memory { 4.GB + (2.GB * (task.attempt -1))}

	if( params.run_mode == 'conda' ) {
		conda 'metaphlan=4.2.4'
	} else {
		container 'biocontainers/metaphlan:4.2.4--pyhdfd78af_0'
	}

	publishDir "${params.outdir}/references",
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_metaphlan.yml")) { return null }
                        else { return fn } }

	output:
	path "metaphlan_db_for_humann", emit: metaphlan_db
	path "versions_metaphlan.yml", emit: versions

	script:
	"""
	mkdir metaphlan_db_for_humann

	metaphlan --install --db_dir metaphlan_db_for_humann --index mpa_vJun23_CHOCOPhlAnSGB_202403

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}": 
            methaphlan: \$(echo \$(metaphlan --version) | sed 's/^.*MetaPhlAn version //; s/Using.*\$//')
            metaphlan_database_version: "mpa_vJun23_CHOCOPhlAnSGB_202403"
	END_VERSIONS
	"""
}
