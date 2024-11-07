#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Processes
include { FASTQC as FASTQC_RAW } from './modules/fastqc/fastqc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/fastqc/fastqc.nf'
include { CUTADAPT_QT } from './modules/cutadapt/cutadapt_QT.nf'
include { MULTIQC_RAW } from './modules/multiqc/multiqc.nf'
include { MULTIQC_FILTERED } from './modules/multiqc/multiqc.nf'
include { AWK_ADD_COLUMN } from './modules/awk/awk.nf'

// QIIME2 Processes
include { QiimeMetadataTabulate } from './modules/qiime2/qiime2.nf'

// Main Workflow
workflow {
    sample_info_ch = Channel
        .fromPath("${params.absolute_path_to_project}/${params.qiime2_metadata}")
        .splitCsv(header: true, sep: '\t')

    // sample_info_ch.subscribe { println it }

    raw_reads_ch = sample_info_ch.map { row ->
        def sampleid = row['sampleid']
        def read1 = file(row['r1_absolute'])
        def read2 = file(row['r2_absolute'])
        tuple(sampleid, [read1, read2])
    }

    // Run FASTQC on Raw Data
    fastqc_raw_ch = raw_reads_ch.map { sampleid, reads ->
        tuple(sampleid, reads, params.raw_fastQC_dir)
    }
        | FASTQC_RAW
    fastqc_raw_ch.collect() | MULTIQC_RAW

    // Run CUTADAPT for quality and length trimming
    trimmed_reads_ch = raw_reads_ch.map { sampleid, reads ->
        tuple(sampleid, reads, params.filtered_fastq_dir)
    }
        | CUTADAPT_QT

    // trimmed_reads_ch.subscribe { println("CUTADAPT_QT output: ${it}") }

    //Process filtered reads for FASTQC on Filtered Data
    fastqc_filtered_ch = trimmed_reads_ch.map { sampleid, r1_filtered, r2_filtered ->
        def filtered_r1_path
            = file("${params.output_dir}/${params.filtered_fastq_dir}/${r1_filtered.name}")
        def filtered_r2_path
            = file("${params.output_dir}/${params.filtered_fastq_dir}/${r2_filtered.name}")
        tuple(sampleid, [filtered_r1_path, filtered_r2_path], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED
    fastqc_filtered_ch.collect() | MULTIQC_FILTERED


    // Begin Qiime2 Analysis
    // Import Metadata and fastQ files
    // Metadata tabulation for visualization

    qiime_metadata_file = file("${params.absolute_path_to_project}/${params.qiime2_metadata}")

    // Update Metadata
    AWK_ADD_COLUMN(qiime_metadata_file)

    // QiimeMetadataTabulate(qiime_metadata_file)
}
