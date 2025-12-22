process GMM_PREDICTION {

	cpus = { 2 + (1 * (task.attempt-1)) }
	memory = { 1.GB + (2.GB * (task.attempt-1)) }

	publishDir = [
		path: { "${params.outdir}" }, 
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_java.yml")) { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda 'conda-forge::openjdk=23.0.2'
	}

	if( params.run_mode == 'container' ) {
		container 'pmaragno/openjdk_23.0.2:latest'
	}

	input:
	path(all_genefamilies_KO_for_omixer)
	path omixer_jar
	path gmm_database

	output:
	path(omixer_output), emit: omixer_output
	path  "versions_java.yml", emit: versions

	script:
	"""
	java -jar ${omixer_jar} -i ${all_genefamilies_KO_for_omixer} -c 0.66 -d ${gmm_database} -o ./omixer_output

	cat <<-END_VERSIONS > versions_java.yml
        "${task.process}":
            java: \$(echo \$(javac -version | sed 's/javac //'))
	END_VERSIONS
        """

}
