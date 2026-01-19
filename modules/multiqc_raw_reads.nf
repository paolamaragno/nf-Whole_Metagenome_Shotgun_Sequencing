process MULTIQC_RAW_READS {

	cpus = { 1 + (1 * (task.attempt-1)) }
	memory = { 2.GB + (2.GB * (task.attempt-1)) }
	
	publishDir = [
		path: { "${params.outdir}/multiqc_on_raw_reads" }, 
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
	path(fastqc_raw_out)

	output:
	path "multiqc_report_raw_reads.html", emit: multiqc_report
	path "multiqc_report_raw_reads_data", emit: data_dir
	path "versions_multiqc.yml", emit: versions

	script:
	"""
	multiqc . -n multiqc_report_raw_reads.html

	cat <<-END_VERSIONS > versions_multiqc.yml
        "${task.process}": 
            multiqc: \$(echo \$(multiqc --version) | sed 's/^.*multiqc //; s/Using.*\$//')
	END_VERSIONS
	"""
}

