process COLLECT_VERSIONS {

	cpus = { 1 * task.attempt }
	memory = { 2.GB * task.attempt }

	if( params.run_mode == 'conda' ) {
		conda 'bioconda::multiqc=1.23'
	} else {
		container 'biocontainers/multiqc:1.30--pyhdfd78af_0'
	}
	
	input:
	path versions

	output:
	path "software_versions.yml"    , emit: yml
	path "software_versions_mqc.yml", emit: mqc_yml
	path "versions.yml"             , emit: versions	

	script:
	template 'dumpsoftwareversions.py'
}

