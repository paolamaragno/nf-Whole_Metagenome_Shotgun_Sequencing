#!/bin/sh

process FASTP {

	cpus = { 5 * task.attempt }
	memory = { 7.GB * task.attempt }

	tag "Fastp on $name"
	publishDir = [
		path: { "${params.outdir}/fastp/${name}" },
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_fastp.yml")) { return null }
			else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::fastp=1.0.1'
	} else {
		container 'biocontainers/fastp:1.0.1--heae3180_0'
	}

	input:
	tuple val(name), path(fastq1), path(fastq2)
	val(length)

	output:
	tuple val(name), file("${name}_R1_001_filtered.fastq"), file("${name}_R2_001_filtered.fastq"), emit: fastp_reads
	file("${name}_fastp.html")
	path  "versions_fastp.yml", emit: versions

	script:
	"""
	fastp \
               	--in1 ${fastq1} \
                --in2 ${fastq2} \
                --out1 ${name}_R1_001_filtered.fastq \
                --out2 ${name}_R2_001_filtered.fastq \
		--html ${name}_fastp.html \
                --cut_front --cut_tail --cut_mean_quality 20 --qualified_quality_phred 15 --cut_window_size 4 --length_required ${length} \
                --detect_adapter_for_pe --disable_trim_poly_g --thread ${task.cpus}

	cat <<-END_VERSIONS > versions_fastp.yml
        "${task.process}": 
            fastp: \$(echo \$(fastp --version) | sed 's/^.*fastp //; s/Using.*\$//')
	END_VERSIONS

	"""
}

