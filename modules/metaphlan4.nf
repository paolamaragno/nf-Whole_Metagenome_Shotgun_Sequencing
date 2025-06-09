#!/bin/sh

process METAPHLAN4 {

	cpus = 7
	memory = 20.GB

	//tag "Metaphlan4 on $sample_id"	
	publishDir "${params.outdir}/metaphlan/${sample_id}", mode: 'copy', saveAs: { filename -> filename.equals('versions_metaphlan.yml') ? null : filename }

	container 'metaphlan4.1.1_latest.sif'

	input:
	tuple val(sample_id), path(processed_fastq)
	path(metaphlan_db)

	output:
	tuple val(sample_id), path("${processed_fastq}"), emit: processed_fastq
	path("${sample_id}_profile.txt"), emit: profile
	path  "versions_metaphlan.yml", emit: versions

	script:
	"""
	metaphlan ${processed_fastq} --input_type fastq  --bowtie2db ${metaphlan_db}  --bowtie2out ${sample_id}.bowtie2.bz2 --samout ${sample_id}.sam.bz2 -o ${sample_id}_profile.txt --nproc ${task.cpus} --read_min_len ${params.metaphlan_read_min_len} --index mpa_vJun23_CHOCOPhlAnSGB_202403

	cat <<-END_VERSIONS > versions_metaphlan.yml
        "${task.process}":
            metaphlan: \$(echo \$(metaphlan -v) | sed 's/^.*metaphlan //; s/Using.*\$//')
	END_VERSIONS
	"""
}
