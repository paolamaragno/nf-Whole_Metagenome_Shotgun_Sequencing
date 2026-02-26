process MULTIQC_FINAL {

	cpus { 1 + (2 * (task.attempt - 1)) }
	memory { 2.GB + (2.GB * (task.attempt - 1)) }
	
	publishDir "${params.outdir}/multiqc", mode: 'copy'
	
	if( params.run_mode == 'conda' ) {
		conda 'bioconda::multiqc==1.23 python=3.10'
	} else {
		container 'biocontainers/multiqc:1.23--pyhdfd78af_0'
	}

	input:
	path software_versions

	output:
	path "software_versions.html"

	script:
	"""
	multiqc -n software_versions.html .

	"""
}

