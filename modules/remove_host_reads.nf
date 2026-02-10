#!/bin/sh

process REMOVE_HOST_READS {

	cpus = { 10 * task.attempt }
	memory = { 30.GB * task.attempt }

	tag "Host reads removal from  $sample_id"
	publishDir = [
		path: { "${params.outdir}/processed_reads/${sample_id}" },
		mode: 'copy',
		saveAs: { fn -> if (fn.equals("versions_bowtie2.yml")) { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
		conda 'bowtie2=2.5.4 samtools=1.22.1'
	} else {
		container 'pmaragno/bowtie2.5.4_samtools1.22.1_cluster'
	}

	input:
	path(bowtie2_idx_folder)
	tuple val(sample_id), path(filtered_fastq1), path(filtered_fastq2)

	output:
	tuple val(sample_id), file("${sample_id}_filtered.final_R1_R2.fastq"), emit: processed_reads
	path  "versions_bowtie2.yml", emit: versions

	script:
	"""
	bowtie2 -x ${bowtie2_idx_folder}/${params.idx_genome} -1 ${filtered_fastq1} -2 ${filtered_fastq2} \
                -S ${sample_id}.sam --very-sensitive-local -p ${task.cpus}

	samtools view -bS ${sample_id}.sam > ${sample_id}.bam
	samtools view -b -f 12 -F 256 ${sample_id}.bam > ${sample_id}.bothunmapped.bam
	samtools sort -n -m 5G -@ 2 ${sample_id}.bothunmapped.bam -o ${sample_id}.bothunmapped.sorted.bam
	samtools fastq ${sample_id}.bothunmapped.sorted.bam -1 ${sample_id}_filtered.final_1.fastq -2 ${sample_id}_filtered.final_2.fastq -0 /dev/null -s /dev/null -n

	cat ${sample_id}_filtered.final_1.fastq ${sample_id}_filtered.final_2.fastq > ${sample_id}_filtered.final_R1_R2.fastq

	cat <<-END_VERSIONS > versions_bowtie2.yml
        "${task.process}":
            bowtie: \$(echo \$(bowtie2-align-s --version | head -n1 | sed 's/bowtie2-align-s version //'))
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
	END_VERSIONS
	"""
}
