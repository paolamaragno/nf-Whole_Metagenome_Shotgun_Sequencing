#!/bin/sh

process FASTP_COLLECT {

	cpus { 1 + (2 * (task.attempt-1)) }
	memory { 2.GB + (2.GB * (task.attempt -1)) }

	publishDir "${params.outdir}/fastp/",
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_multiqc.yml")) { return null }
			else { return fn } }

	if( params.run_mode == 'conda' ) {
                conda 'bioconda::multiqc==1.34 python=3.10'
        } else {
                container 'biocontainers/multiqc:1.34--pyhdfd78af_0'
        }

	input:
	path(json)

	output:
	file("fastp_overall_report.html")
	path  "versions_multiqc.yml", emit: versions

	script:
	"""
	multiqc . -n fastp_overall_report.html

	cat <<-END_VERSIONS > versions_multiqc.yml
        "${task.process}": 
            multiqc: \$(echo \$(multiqc --version) | sed 's/^.*multiqc //; s/Using.*\$//')
	END_VERSIONS

	"""
}

