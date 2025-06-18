process COLLECT_VERSIONS {

	cpus = 1
	memory = 5.GB
	
	container 'multiqc_latest.sif'

	input:
	path versions

	output:
	path "software_versions.yml"    , emit: yml
	path "software_versions_mqc.yml", emit: mqc_yml
    	path "versions.yml"             , emit: versions	

	script:
	template 'dumpsoftwareversions.py'
}

