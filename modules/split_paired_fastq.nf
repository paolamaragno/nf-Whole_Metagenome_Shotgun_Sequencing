#!/bin/sh

process SPLIT_PAIRED_FASTQ {

	cpus = { 5 * task.attempt }
	memory = { 7.GB * task.attempt }

	tag "Split paired fastq of $name"

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::seqkit=2.12.0'
	} else {
		container 'biocontainers/seqkit:2.12.0--he881be0_1'
	}

	input:
	tuple val(name), path(merged_fastq)

	output:
	tuple val(name), file("*part_001.fastq"), file("*part_002.fastq"), emit: splitted_fastq
	path  "versions_seqkit.yml", emit: versions

	script:
	"""
	seqkit split2 -p 2 ${merged_fastq} -O .

	cat <<-END_VERSIONS > versions_seqkit.yml
        "${task.process}": 
            seqtk: \$(echo \$(seqkit --version) | sed 's/^.*seqkit //; s/Using.*\$//')
	END_VERSIONS

	"""
}

