#!/bin/sh

process FASTQC_FILTERED_READS {

	cpus = { 3 + (1 * (task.attempt-1)) }
	memory = { 12.GB + (2.GB * (task.attempt-1))}

	tag "Fastqc on filtered reads of $name"

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::fastqc'
    } else {
		container 'biocontainers/fastqc:0.12.1--hdfd78af_0'
    }

	input:
	tuple val(name), path(filtered_fastq)

	output:
	path "*_fastqc.{zip,html}", emit: fastqc_filtered_out
	path  "versions_fastqc.yml", emit: versions

	script:
	"""
	fastqc ${filtered_fastq} 

	cat <<-END_VERSIONS > versions_fastqc.yml
        "${task.process}": 
            fastqc: \$(echo \$(fastqc --version) | sed 's/^.*fastqc //; s/Using.*\$//')
	END_VERSIONS

	"""
}

