#!/bin/sh

process COPY_INDEX_GENOME2 {

	cpus = 1
	memory = 5.GB
	
	publishDir "${params.outdir}/bowtie_index", mode: 'copy', saveAs: { filename -> filename.equals('versions_bowtie_index_genome2.yml') ? null : filename }

	input:
	path(params.genome_index_2)

	output:
	path(genome2_index), emit: genome2_index
	path  "versions_bowtie_index_genome2.yml", emit: versions
	
	script:
	"""
	cp -r ${genome_index_2} genome2_index

	cat <<-END > versions_bowtie_index_genome2.yml
        "${task.process}":
            Bowtie: Bowtie index provided as input
	END
	"""
}
