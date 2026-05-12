#!/bin/sh

process HUMANN_INSTALL_DB_NUCLEOTIDES {

	cpus { 4 + (2 * (task.attempt - 1)) }
        memory { 16.GB + (2.GB * (task.attempt - 1)) }

	container 'pmaragno/humann_3.9_updated:latest'

	publishDir "${params.outdir}/references",
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_humann_install_db_nucleotides.yml")) { return null }
                        else { return fn } }

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
