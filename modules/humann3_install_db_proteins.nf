#!/bin/sh

process HUMANN_INSTALL_DB_PROTEINS {

	cpus = 28
        memory = 375.GB

	conda 'bioconda::humann=3.9'

	publishDir "${params.outdir}", mode: 'copy', saveAs: { filename -> filename.equals('versions_humann_install_db_proteins.yml') ? null : filename }

	output:
	path "humann_db/uniref", emit: humann_db_proteins
	path "versions_humann_install_db_proteins.yml", emit: versions

	script:
	"""
	humann_databases --download uniref uniref90_diamond humann_db

	cat <<-END_VERSIONS > versions_humann_install_db_proteins.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
