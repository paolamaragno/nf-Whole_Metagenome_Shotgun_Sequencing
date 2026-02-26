#!/bin/sh

process SPLIT_PAIRED_FASTQ {

	cpus { 5 + (2 * (task.attempt - 1)) }
	memory { 7.GB + (2.GB * (task.attempt - 1)) }

	tag "Split paired fastq of $sample"

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::seqkit=2.12.0'
	} else {
		container 'biocontainers/seqkit:2.12.0--he881be0_1'
	}

	input:
	tuple val(sample), path(merged_fastq)

	output:
	tuple val(sample), file("*part_001.fastq"), file("*part_002.fastq"), emit: splitted_fastq
	path  "versions_seqkit.yml", emit: versions

	script:
	"""
	seqkit split2 -p 2 ${merged_fastq} -O .

	cat <<-END_VERSIONS > versions_seqkit.yml
        "${task.process}": 
            seqkit: \$(echo \$(seqkit version) | sed 's/^.*seqkit //')
	END_VERSIONS

	"""
}

