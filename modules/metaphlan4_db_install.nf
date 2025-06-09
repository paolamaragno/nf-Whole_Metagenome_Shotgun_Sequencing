#!/bin/sh

process METAPHLAN_INSTALL {

	cpus = 28
        memory = 375.GB

	container 'metaphlan4.1.1_latest.sif'

	publishDir "${params.outdir}/metaphlan_db", mode: 'copy', saveAs: { filename -> filename.equals('versions_metaphlan.yml') ? null : filename }

	output:
	path "metaphlan_db", emit: metaphlan_db
	path "versions_metaphlan.yml", emit: versions

	script:
	"""
	mkdir -p metaphlan_db

	metaphlan --install --index mpa_vJun23_CHOCOPhlAnSGB_202403 --bowtie2db metaphlan_db 

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}": 
            metaphlan: \$(echo \$(metaphlan -v) | sed 's/^.*metaphlan //; s/Using.*\$//')
	END_VERSIONS
	"""
}
