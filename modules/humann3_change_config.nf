#!/bin/sh

process HUMANN_CHANGE_CONFIG {

        cpus = 1
        memory = 2.GB

        conda 'bioconda::humann=3.9'

	input:
	path(utility_mapping_dir)

	output:
	path "versions_humann_change_config.yml", emit: versions

        script:
        """
	humann_config --update database_folders utility_mapping ${utility_mapping_dir}

        cat <<-END_VERSIONS > versions_humann_change_config.yml
        "${task.process}": 
            humann: \$(echo \$(humann --version) | sed 's/^.*humann //; s/Using.*\$//')
        END_VERSIONS
        """
}


