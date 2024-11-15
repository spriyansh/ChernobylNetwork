#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Processes
include { FASTQC as FASTQC_RAW } from './modules/fastqc/fastqc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/fastqc/fastqc.nf'
include { CUTADAPT_QT } from './modules/cutadapt/cutadapt_QT.nf'
include { MULTIQC_RAW } from './modules/multiqc/multiqc.nf'
include { MULTIQC_FILTERED } from './modules/multiqc/multiqc.nf'

// QIIME2 Processes
include { QiimeMetadataTabulate } from './modules/qiime2/qiime2.nf'
include { UPDATE_METADATA_COL as UpdateFilteredReads } from './modules/python/update_metadata.nf'
include { QiimeImportReads } from './modules/qiime2/qiime2.nf'
include { Qiime2DeIonize } from './modules/qiime2/qiime2.nf'
include { FeatureTableSummary } from './modules/qiime2/qiime2.nf'
include { FeatureTableTabulateSeq } from './modules/qiime2/qiime2.nf'
include { DeionizeStatTabulate } from './modules/qiime2/qiime2.nf'

// Main Workflow
workflow {
    sample_info_ch = Channel
        .fromPath("${params.absolute_path_to_project}/${params.qiime2_metadata}")
        .splitCsv(header: true, sep: '\t')

    // // sample_info_ch.subscribe { println it }
    raw_reads_ch = sample_info_ch.map { row ->
        def sampleid = row['sampleid']
        def read1 = file(row['r1_absolute'])
        def read2 = file(row['r2_absolute'])
        tuple(sampleid, [read1, read2])
    }

    // // Run FASTQC on Raw Data
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


    // Update Metadata
    qiime_metadata_file = file("${params.absolute_path_to_project}/${params.qiime2_metadata}")
    UpdatedQiime2Metadata = UpdateFilteredReads(
        tuple(
            qiime_metadata_file,
            "Qiime2MetadataInput.tsv",
            "r1_absolute",
            "r2_absolute",
            "${params.output_dir}/${params.filtered_fastq_dir}"
        )
    )

    //Process filtered reads for FASTQC on Filtered Data
    fastqc_filtered_ch = trimmed_reads_ch.map { sampleid, r1_filtered, r2_filtered ->
        tuple(sampleid, [r1_filtered, r2_filtered], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED
    fastqc_filtered_ch.collect() | MULTIQC_FILTERED

    // Create Qiime2Metdata
    tabulatedMetadata = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) } | QiimeMetadataTabulate

    // Import Data
    QiimeReads_ch = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) } | QiimeImportReads

    // Deionize
    DeIonize_ch = QiimeReads_ch.map { demux_qza, demux_summary ->
        file(demux_qza)
    }
        | Qiime2DeIonize

    // Create Visuals
    DeIonize_ch.map { table_qza, rep_seqs, deionize_stats -> tuple(table_qza, qiime_metadata_file) } | FeatureTableSummary
    DeIonize_ch.map { table_qza, rep_seqs, deionize_stats -> file(rep_seqs) } | FeatureTableTabulateSeq
    DeIonize_ch.map { table_qza, rep_seqs, deionize_stats -> file(deionize_stats) } | DeionizeStatTabulate
}
