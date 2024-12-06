#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Processes
include { FASTQC } from './modules/fastqc/fastqc.nf'
include { MULTIQC_RAW } from './modules/multiqc/multiqc.nf'

// QIIME2 Common
include { Qiime2Tabulate as TabulateMetadata } from './modules/qiime2/qiime2.nf'
include { Qiime2ImportReads } from './modules/qiime2/qiime2.nf'
include { Qiime2SummaryToQVZ } from './modules/qiime2/qiime2.nf'

// Qiime2 ASV and OTUs
include { DADA2Denoise } from './modules/qiime2/qiime2.nf'
include { VSearchCluster } from './modules/qiime2/qiime2.nf'

// Qiime2 Common Workflows Assign Sequence
include { BIOM_TSV as FeatureTabToTSV } from './modules/qiime2/qiime2_exports.nf'

// Call Workflows 
include { VisualSummary } from './modules/sub_workflows/visual_summary_subflow.nf'
include { SequenceAssign } from './modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { ExportData } from './modules/sub_workflows/export_tables_subflow.nf'
include { Phylogeny } from './modules/sub_workflows/compute_phylogeny.nf'

// Main Workflow
workflow {

    // Load QIIME2 Metadata-File
    sample_info_ch = Channel
        .fromPath("${params.qiime2_metadata}")
        .splitCsv(header: true, sep: '\t')

    // Extract Columns with absolute path to the indvidual FASTQ-files
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
        | FASTQC

    // Compile the Multi-QC Reports
    fastqc_raw_ch.collect() | MULTIQC_RAW

    // Update Metadata Columns to point to filtered files
    qiime_metadata_ch = Channel.fromPath(file("${params.qiime2_metadata}"))

    // Read
    Qiime2Reads_ch =qiime_metadata_ch.map(metadata -> file(metadata)) | Qiime2ImportReads

    // Summarize
    Qiime2Reads_ch.map { demux_reads_qza -> file(demux_reads_qza) } | Qiime2SummaryToQVZ

    // Deionize-DADA2
    DADA2_Denoised_ch = Qiime2Reads_ch.map { demux_qza -> file(demux_qza) } | DADA2Denoise

    // Combine DADA2_Denoised_ch with Metadata file channel
    DADA2_Denoised_ch
        .combine(qiime_updated_metadata_ch)
        .set { Qiime2Denoise_ch }

    // Summarize Denoise Statistics
    Qiime2Denoise_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(file(denoise_stats), "dada2-denoising-stats.qzv") } | TabulateDenoiseStats

    // Compute OTUs
    VCluster_ch = Qiime2Denoise_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(table_qza, rep_seqs) } | VSearchCluster

    // Combine with metadata
    VCluster_ch
        .combine(qiime_updated_metadata_ch)
        .set { Qiime2_Cluster_ch }

    // Prepare Common Chanels
    asv_chanel = Qiime2Denoise_ch.map { table_qza, repSeq_qza, rm_denoise_stats, metadata ->
        tuple('ASV', table_qza, repSeq_qza, metadata)
    }
    otu_chanel = Qiime2_Cluster_ch.map { table_qza, repSeq_qza, rm_new_seqs, metadata ->
        tuple('OTU', table_qza, repSeq_qza, metadata)
    }
    // Include and Run the Subworkflow
    asv_otu_common_ch = asv_chanel.concat(otu_chanel)

    // Run Common Workflow for Summarization
    VisualSummary(asv_otu_common_ch)

    // AssignTaxa from SilvaDB
    asv_otu_tax_common_ch = SequenceAssign(asv_otu_common_ch)

    // Export Data
    ExportData(asv_otu_tax_common_ch)

    // Compute Phylogeny
    Phylogeny(asv_otu_tax_common_ch)
}
