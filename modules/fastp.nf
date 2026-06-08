#!/bin/sh

process FASTP {

	cpus { 12 + (2 * (task.attempt-1)) }
	memory { 10.GB + (2.GB * (task.attempt -1)) }
	time { 12.h * task.attempt }

	tag "Fastp on $name"
	publishDir "${params.outdir}/fastp/${name}",
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_fastp.yml") || fn.equals("${name}_fastp.json")) { return null }
			else { return fn } }

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::fastp=1.3.3'
	} else {
		container 'biocontainers/fastp:1.3.3--h43da1c4_0'
	}

	input:
	tuple val(name), path(fastq1), path(fastq2)

	output:
	tuple val(name), file("${name}_R1_001_filtered.fastq"), file("${name}_R2_001_filtered.fastq"), emit: fastp_reads
	path "${name}_fastp.html", emit: html
	path "${name}_fastp.json", emit: json
	path "versions_fastp.yml", emit: versions

	script:
	"""
	fastp \
               	--in1 ${fastq1} \
                --in2 ${fastq2} \
                --out1 ${name}_R1_001_filtered.fastq \
                --out2 ${name}_R2_001_filtered.fastq \
                --html ${name}_fastp.html \
                -j ${name}_fastp.json \
                --cut_front --cut_front_window_size 1 --cut_front_mean_quality 20 \
                --cut_tail --cut_tail_window_size 1 --cut_tail_mean_quality 20 \
                --cut_right --cut_right_window_size 4 --cut_right_mean_quality 15 \
                --length_required 100 \
                --detect_adapter_for_pe --disable_trim_poly_g --thread ${task.cpus}

	cat <<-END_VERSIONS > versions_fastp.yml
        "${task.process}": 
            fastp: \$(echo \$(fastp --version) | sed 's/^.*fastp //; s/Using.*\$//')
	END_VERSIONS

	"""
}

