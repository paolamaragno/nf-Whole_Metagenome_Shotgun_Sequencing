#!/bin/sh

process TRIMMOMATIC {

	cpus = 2
	memory = 7.GB
	
	//tag "Trimmomatic on $name"
	publishDir "${params.outdir}/trimmomatic/${name}", mode: 'copy', saveAs: { filename -> filename.equals('versions_trimmomatic.yml') ? null : filename }
	
	container 'trimmomatic_0.39.sif'

	input:
	tuple val(name), path(fastq1), path(fastq2), val(genome_for_mapping)

	output:
	tuple val(name), file("${name}_R1_001_filtered.fastq"), file("${name}_R2_001_filtered.fastq"), emit: trimmomatic_reads
	path  "versions_trimmomatic.yml", emit: versions

	script:
	"""
	trimmomatic PE -threads ${task.cpus} -phred33 -trimlog ${name}_trimmomatic.log ${fastq1} ${fastq2} \
                ${name}_R1_001_filtered.fastq ${name}_R1_001_unpaired.fastq  ${name}_R2_001_filtered.fastq ${name}_R2_001_unpaired.fastq \
                ILLUMINACLIP:${workflow.projectDir}/trimmomatic_adapters/TruSeq3-PE-2.fa:2:30:10 \
                LEADING:20 TRAILING:20 SLIDINGWINDOW:4:15 MINLEN:${params.trimmomatic_MINLEN}	

	cat <<-END_VERSIONS > versions_trimmomatic.yml
        "${task.process}":
            Trimmomatic: \$(echo \$(trimmomatic -version) | sed 's/^.*trimmomatic //; s/Using.*\$//')
	END_VERSIONS

	"""
}

