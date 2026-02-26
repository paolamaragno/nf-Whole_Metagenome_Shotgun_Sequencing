#!/bin/sh

process FASTQC_RAW_READS {

	cpus { 3 + (2 * (task.attempt - 1))}
	memory { 6.GB + (2.GB * (task.attempt -1))}

	tag "Fastqc on raw reads of $sample"

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::fastqc'
	} else {
		container 'biocontainers/fastqc:0.12.1--hdfd78af_0'
	}

	input:
	tuple val(sample), path(fastq1), path(fastq2)

	output:
	path "*_fastqc.{zip,html}", emit: fastqc_raw_out
	path  "versions_fastqc.yml", emit: versions

	script:
	"""
	fastqc -t ${task.cpus} ${fastq1} ${fastq2}

	cat <<-END_VERSIONS > versions_fastqc.yml
        "${task.process}": 
            fastqc: \$(echo \$(fastqc --version) | sed 's/^.*fastqc //; s/Using.*\$//')
	END_VERSIONS

	"""
}

