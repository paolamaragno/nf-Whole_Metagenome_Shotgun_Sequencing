process MULTIQC {

	cpus = 2
	memory = 5.GB
	
	publishDir "${params.outdir}/multiqc", mode: 'copy'
	
	container 'multiqc_latest.sif'

	input:
	path software_versions

	output:
	path "software_versions.html"

	script:
	"""
	multiqc -n software_versions.html .

	"""
}

