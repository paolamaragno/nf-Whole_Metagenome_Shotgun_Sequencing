#!/bin/sh

process METAPHLAN4 {

	cpus = { 8 + (1 * (task.attempt-1)) }
	memory = { 30.GB + (2.GB * (task.attempt-1)) }

	tag "Metaphlan4 on $sample_id"	
	publishDir = [
		path: { "${params.outdir}/metaphlan4.1.1/${sample_id}" },
		mode: 'copy',
		saveAs: { fn -> if (fn == "versions_metaphlan.yml" || fn == "${processed_fastq}") { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda "metaphlan=4.1.1"
    } else {
		container 'biocontainers/metaphlan:4.1.1--pyhdfd78af_0'
    }

	input:
	tuple val(sample_id), path(processed_fastq)
	path(metaphlan_db)
	val(length)

	output:
	tuple val(sample_id), path("${processed_fastq}"), emit: processed_fastq
	path("${sample_id}_profile.txt"), emit: profile
	path  "versions_metaphlan.yml", emit: versions

	script:
	"""
	metaphlan ${processed_fastq} --input_type fastq  --bowtie2db ${metaphlan_db}  --bowtie2out ${sample_id}.bowtie2.bz2 --samout ${sample_id}.sam.bz2 -o ${sample_id}_profile.txt --nproc ${task.cpus} --read_min_len ${length} -x mpa_vJun23_CHOCOPhlAnSGB_202403

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}":
            methaphlan: \$(echo \$(metaphlan --version) | sed 's/^.*MetaPhlAn version //; s/Using.*\$//')
            metaphlan_database_version: "${params.metaphlan_db_index}"
	END_VERSIONS
	"""
}
