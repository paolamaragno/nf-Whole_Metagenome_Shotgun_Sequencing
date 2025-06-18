#!/bin/sh

process BOWTIE2_SAMTOOLS_ONE_INDEX {

	cpus = 7
	memory = 13.GB
	
	//tag "Bowtie2 on $sample_id"	
	publishDir "${params.outdir}/processed_reads/${sample_id}", mode: 'copy', saveAs: { filename -> filename.equals('versions_bowtie2_samtools.yml') ? null : filename }

	conda 'bowtie2 samtools'

	input:
	path(bowtie2_idx_folder)
	tuple val(sample_id), path(filtered_fastq1), path(filtered_fastq2)

	output:
	tuple val(sample_id), file("${sample_id}_filtered.final_R1_R2.fastq.gz"), emit: processed_reads
	path  "versions_bowtie2_samtools.yml", emit: versions

	script:
	"""
        bowtie2 -x ${bowtie2_idx_folder}/${params.idx_genome_1} -1 ${filtered_fastq1} -2 ${filtered_fastq2} \
                -S ${sample_id}.sam --very-sensitive-local -p ${task.cpus}

	samtools view -bS ${sample_id}.sam > ${sample_id}.bam
        samtools view -b -f 12 -F 256 ${sample_id}.bam > ${sample_id}.bothunmapped.bam
        samtools sort -n -m 5G -@ 2 ${sample_id}.bothunmapped.bam -o ${sample_id}.bothunmapped.sorted.bam
        samtools fastq ${sample_id}.bothunmapped.sorted.bam -1 >(gzip > ${sample_id}_filtered.final_1.fastq.gz) -2 >(gzip > ${sample_id}_filtered.final_2.fastq.gz) -0 /dev/null -s /dev/null -n

        cat ${sample_id}_filtered.final_1.fastq.gz ${sample_id}_filtered.final_2.fastq.gz > ${sample_id}_filtered.final_R1_R2.fastq.gz

	cat <<-END_VERSIONS > versions_bowtie2_samtools.yml
        "${task.process}":
            bowtie: \$(echo \$(bowtie2-align-s --version | head -n1 | sed 's/bowtie2-align-s version //'))
            samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
	END_VERSIONS
	"""
}
