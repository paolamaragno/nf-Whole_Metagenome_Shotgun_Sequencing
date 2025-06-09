#!/bin/sh

process GMM_PREDICTION {

	cpus = 2
	memory = 5.GB 

	publishDir "${params.outdir}", mode: 'copy', saveAs: { filename -> filename.equals('versions_java.yml') ? null : filename }

	container 'java_latest.sif'

	input:
	path(all_genefamilies_KO_for_omixer)

	output:
	path(omixer_output), emit: omixer_output
	path  "versions_java.yml", emit: versions

	script:
	"""
	java -jar ${workflow.projectDir}/omixer-rpm-1.1.jar -i ${all_genefamilies_KO_for_omixer} -c 0.66 -d ${workflow.projectDir}/GMMs.v1.07.txt -o ./omixer_output

	cat <<-END_VERSIONS > versions_java.yml
        "${task.process}":
            java: \$(echo \$(javac -version | sed 's/javac //'))
	END_VERSIONS
	"""
}
