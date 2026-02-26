#!/bin/sh

process COPY_GENOME_INDEX {

	cpus { 1 + (2 * (task.attempt -1)) }
	memory { 5.GB + (2.GB * (task.attempt -1)) }

	input:
	path(genome_index)

	output:
	path(genome_index), emit: genome_index
	path  "versions_copy_index_genome.yml", emit: versions

	script:
	"""
	cat <<-END > versions_copy_index_genome.yml
        "${task.process}":
            reference_genome: "${params.genome_fasta}"
            genome_index: "${params.idx_genome}"
	END

	"""
}
