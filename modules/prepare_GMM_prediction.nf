#!/bin/sh

process PREPARE_GMM_PREDICTION {

	cpus = { 1 + (1 * (task.attempt-1)) }
	memory = { 2.GB + (2.GB * (task.attempt-1)) }

	if( params.run_mode == 'conda' ) {
		conda 'conda-forge::r-readr'
        }

        if( params.run_mode == 'container' ) {
		container 'nf-core/bioconductor-edger_bioconductor-ihw_bioconductor-limma_r-dplyr_r-readr:edea0f9fbaeba3a0'
        }

	input:
	path(all_genefamilies_KO_not_renamed)
	path(R_file_input_preparation)

	output:
	path('./all_genefamilies_KO_for_omixer.tsv'), emit: all_genefamilies_KO_for_omixer 
	path  "versions_R.yml", emit: versions

	script:
	"""
	Rscript ${R_file_input_preparation} ${all_genefamilies_KO_not_renamed}

	cat <<END_VERSIONS > versions_R.yml
        "${task.process}":
            R: \$(R --version | head -n1 | awk '{print \$3}')
	END_VERSIONS
	"""
}
