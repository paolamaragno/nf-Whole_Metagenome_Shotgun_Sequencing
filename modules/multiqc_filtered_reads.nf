process MULTIQC_FILTERED_READS {

	cpus = { 1 * task.attempt }
	memory = { 2.GB * task.attempt }
	
	publishDir = [
		path: { "${params.outdir}/multiqc_on_filtered_reads" }, 
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_multiqc.yml")) { return null }
                        else { return fn } }
	]
	
	if( params.run_mode == 'conda' ) {
		conda 'bioconda::multiqc==1.23 python=3.10'
	} else {
		container 'biocontainers/multiqc:1.23--pyhdfd78af_0'
	}

	input:
	path(fastqc_out)

	output:
	path "multiqc_report_filtered_reads.html", emit: multiqc_report
	path "versions_multiqc.yml", emit: versions

	script:
	"""
	multiqc . -n multiqc_report_filtered_reads.html

	cat <<-END_VERSIONS > versions_multiqc.yml
        "${task.process}": 
            multiqc: \$(echo \$(multiqc --version) | sed 's/^.*multiqc //; s/Using.*\$//')
	END_VERSIONS
	"""
}

