#!/bin/sh

process HUMANN_INSTALL_DB_MAPPING_UTIL {

	cpus = 28
        memory = 375.GB

	conda 'bioconda::humann=3.9'

	publishDir "${params.outdir}", mode: 'copy', saveAs: { filename -> filename.equals('versions_humann_install_db_mapping_utils.yml') ? null : filename }

	output:
	path "humann_db/utility_mapping", emit: humann_db_utilities
	path "versions_humann_install_db_mapping_utils.yml", emit: versions

	script:
	"""
	humann_databases --download utility_mapping full humann_db

	cat <<-END_VERSIONS > versions_humann_install_db_mapping_utils.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
