#!/bin/sh

process HUMANN_INSTALL_DB_NUCLEOTIDES {

	cpus = 28
        memory = 375.GB

	conda 'bioconda::humann=3.9'

	publishDir "${params.outdir}", mode: 'copy', saveAs: { filename -> filename.equals('versions_humann_install_db_nucleotides.yml') ? null : filename }

	output:
	path "humann_db/chocophlan", emit: humann_db_nucleo
	path "versions_humann_install_db_nucleotides.yml", emit: versions

	script:
	"""
	humann_databases --download chocophlan full humann_db 

	cat <<-END_VERSIONS > versions_humann_install_db_nucleotides.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
