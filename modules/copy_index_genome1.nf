#!/bin/sh

process COPY_INDEX_GENOME1 {

	cpus = 1
	memory = 5.GB

	publishDir "${params.outdir}/bowtie_index", mode: 'copy', saveAs: { filename -> filename.equals('versions_bowtie_index_genome1.yml') ? null : filename }
	
	input:
	path(genome_index_1)

	output:
	path(genome1_index), emit: genome1_index
	path  "versions_bowtie_index_genome1.yml", emit: versions

	script:
	"""
	cp -r ${genome_index_1} genome1_index

	cat <<-END > versions_bowtie_index_genome1.yml
        "${task.process}":
            Bowtie: Bowtie index provided as input
	END
	"""
}
