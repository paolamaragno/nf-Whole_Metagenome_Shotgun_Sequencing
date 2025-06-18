#!/bin/sh

process BOWTIE2_INDEX_GENOME1 {

	cpus = 7
	memory = 7.GB

	publishDir "${params.outdir}/bowtie_index", mode: 'copy', saveAs: { filename -> filename.equals('versions_bowtie_index_genome1.yml') ? null : filename }
	
	conda 'bowtie2'

	input:
	path(genome_fasta_1)

	output:
	path("genome1_index"), emit: genome1_index
	path  "versions_bowtie_index_genome1.yml", emit: versions

	script:
	"""
	mkdir -p genome1_index

	bowtie2-build ${genome_fasta_1} genome1_index/${params.idx_genome_1} --threads ${task.cpus}

	cat <<-END > versions_bowtie_index_genome1.yml
        "${task.process}":
            bowtie: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
	END
	"""
}
