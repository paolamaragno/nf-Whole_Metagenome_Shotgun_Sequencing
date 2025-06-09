#!/bin/sh

process BOWTIE2_INDEX_GENOME2 {

	cpus = 7
	memory = 7.GB
	
	publishDir "${params.outdir}/bowtie_index", mode: 'copy', saveAs: { filename -> filename.equals('versions_bowtie_index_genome2.yml') ? null : filename }

	conda 'bowtie2'

	input:
	path(genome_fasta_2)

	output:
	path("genome2_index"), emit: genome2_index
	path  "versions_bowtie_index_genome2.yml", emit: versions
	
	script:
	"""
	mkdir -p genome2_index

	bowtie2-build ${genome_fasta_2} genome2_index/${params.idx_genome_2} --threads ${task.cpus}

	cat <<-END > versions_bowtie_index_genome2.yml
        "${task.process}":
            bowtie: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
	END
	"""
}
