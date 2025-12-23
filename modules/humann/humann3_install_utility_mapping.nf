#!/bin/sh

process HUMANN_INSTALL_UTILITY_MAPPING {

	cpus = { 2 + (1 * (task.attempt-1)) }
        memory = { 5.GB + (2.GB * (task.attempt-1)) }

	conda 'biobakery::humann=3.9'

	publishDir = [
		path: { "${params.outdir}/references" },
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_humann_install_utility_mapping.yml")) { return null }
                        else { return fn } }
	]

	output:
	path "humann_db/utility_mapping", emit: humann_utility_mapping
	path "versions_humann_install_utility_mapping.yml", emit: versions

	script:
	"""
	humann_databases --download utility_mapping full humann_db --update-config no

	cat <<-END_VERSIONS > versions_humann_install_utility_mapping.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
	END_VERSIONS
	"""
}
