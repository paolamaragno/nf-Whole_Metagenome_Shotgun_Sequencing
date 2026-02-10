#!/bin/sh

process HUMANN_INSTALL_DB_PROTEINS {

	cpus = { 2 * task.attempt }
        memory = { 5.GB * task.attempt }

	if( params.run_mode == 'conda' ) {
		conda 'biobakery::humann=3.9'
	} else {
		container 'biocontainers/humann:3.9--py312hdfd78af_0'
	}

	publishDir = [
		path: { "${params.outdir}/references" },
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_humann_install_db_proteins.yml")) { return null }
                        else { return fn } }
	]

	output:
	path "humann_db/uniref", emit: humann_db_proteins
	path "versions_humann_install_db_proteins.yml", emit: versions

	script:
	"""
	humann_databases --download uniref uniref90_diamond humann_db --update-config no

	cat <<-END_VERSIONS > versions_humann_install_db_proteins.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
