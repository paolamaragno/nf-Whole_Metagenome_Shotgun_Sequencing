#!/bin/sh

process BUILD_GENOME_INDEX {

	cpus = { 7 * task.attempt }
	memory { 8.GB * task.attempt }

	publishDir = [
		path: {"${params.outdir}/references" },
		mode: 'copy',
		enabled: params.save_reference,
		saveAs: { fn -> if (fn.equals("versions_bowtie_index_genome.yml")) { return null }
                        else { return fn } }
	]

	if( params.run_mode == 'conda' ) {
                conda 'bowtie2=2.5.4'
	} else {
                container 'biocontainers/bowtie2:2.5.4--he96a11b_6'
	}

	input:
	path(genome_fasta)

	output:
	path("genome_index"), emit: genome_index
	path  "versions_bowtie_index_genome.yml", emit: versions

	script:
	"""
	mkdir genome_index

	bowtie2-build ${genome_fasta} genome_index/${params.idx_genome} --threads ${task.cpus}

	cat <<-END > versions_bowtie_index_genome.yml
        "${task.process}":
            bowtie: \$(echo \$(bowtie2-build --version | head -n1 | sed 's/^.*bowtie2-build-s version //'))
            reference_genome: "${params.genome_fasta}"
            genome_index: "${params.idx_genome}"
	END
	"""
}
