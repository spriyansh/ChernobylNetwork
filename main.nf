#! /usr/bin/env nextflow
nextflow.enable.dsl = 2

include { FASTQC } from './modules/fastqc/fastqc.nf'
include { MULTIQC } from './modules/multiqc/multiqc.nf'

workflow {
    sample_info_ch = Channel
        .fromPath(params.seq_metadata)
        .splitCsv(header: true, sep: '\t')

    reads_ch = sample_info_ch.map { row ->
        def sample_id = row.SampleID
        def r1 = file("${params.fastq_dir}/${row.R1_filename}")
        def r2 = file("${params.fastq_dir}/${row.R2_filename}")
        tuple(sample_id, [r1, r2])
    }

    reads_ch | FASTQC

    multiqc_input_ch = Channel.fromPath("${params.outdir}/fastqc", type: 'dir')
    multiqc_input_ch | MULTIQC
}
