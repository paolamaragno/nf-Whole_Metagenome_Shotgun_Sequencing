#!/bin/sh

process PREPARE_GMM_PREDICTION {

	cpus = 1
	memory = 5.GB

	conda 'r-base conda-forge::r-readr'

	input:
	path(all_genefamilies_KO_not_renamed)

	output:
	path('./all_genefamilies_KO_for_omixer.tsv'), emit: all_genefamilies_KO_for_omixer 
	path  "versions_R.yml", emit: versions

	script:
	"""
	Rscript ${workflow.projectDir}/modules/prepare_file_for_omizer.R ${all_genefamilies_KO_not_renamed}

	cat <<-END_VERSIONS > versions_R.yml
        "${task.process}":
            R: \$(echo \$(R --version | head -n1 | sed 's/R version //' | sed 's/(2024-02-29) -- "Angel Food Cake"//'))
	END_VERSIONS
	"""
}
