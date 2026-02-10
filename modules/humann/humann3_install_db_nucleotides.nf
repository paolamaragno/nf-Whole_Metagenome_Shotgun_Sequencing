#!/bin/sh

process HUMANN_INSTALL_DB_NUCLEOTIDES {

	cpus = { 2 * task.attempt }
        memory = { 3.GB * task.attempt }

	if( params.run_mode == 'conda' ) {
		conda 'biobakery::humann=3.9'
	} else {
		container 'biocontainers/humann:3.9--py312hdfd78af_0'
	}

	publishDir = [
		path: { "${params.outdir}/references" },
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_humann_install_db_nucleotides.yml")) { return null }
                        else { return fn } }
	]

	output:
	path "humann_db/chocophlan", emit: humann_db_nucleo
	path "versions_humann_install_db_nucleotides.yml", emit: versions

	script:
	"""
	humann_databases --download chocophlan full humann_db  --update-config no

	cat <<-END_VERSIONS > versions_humann_install_db_nucleotides.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
