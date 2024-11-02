#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Channels
include { FASTQC as FASTQC_RAW } from './modules/fastqc/fastqc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/fastqc/fastqc.nf'
include { CUTADAPT_QT } from './modules/cutadapt/cutadapt_QT.nf'

// Main Workflow
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

    // Run FASTQC on Raw Data
    fastqc_raw_ch = reads_ch.map { sample_id, reads ->
        tuple(sample_id, reads, params.raw_fastQC_dir)
    }
        | FASTQC_RAW

    // Run CUTADAPT for quality and length trimming
    trimmed_reads_ch = reads_ch.map { sample_id, reads ->
        tuple(sample_id, reads, params.filtered_fastq_dir)
    }
        | CUTADAPT_QT

    // Process filtered reads for FASTQC on Filtered Data
    fastqc_filtered_ch = trimmed_reads_ch.map { sample_id, r1_filtered, r2_filtered ->
        tuple(sample_id, [r1_filtered, r2_filtered], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED
}
