#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Processes
include { FASTQC as FASTQC_RAW } from './modules/fastqc/fastqc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/fastqc/fastqc.nf'
include { CUTADAPT_QT } from './modules/cutadapt/cutadapt_QT.nf'
include { MULTIQC_RAW } from './modules/multiqc/multiqc.nf'
include { MULTIQC_FILTERED } from './modules/multiqc/multiqc.nf'

// QIIME2 Common
include { Qiime2Tabulate as TabulateMetadata } from './modules/qiime2/qiime2.nf'
include { Qiime2Tabulate as TabulateDenoiseStats } from './modules/qiime2/qiime2.nf'
include { UPDATE_METADATA_COL as UpdateFilteredReads } from './modules/python/update_metadata.nf'
include { Qiime2ImportReads } from './modules/qiime2/qiime2.nf'
include { Qiime2SummaryToQVZ } from './modules/qiime2/qiime2.nf'

// Qiime2 ASV and OTUs
include { DADA2Denoise } from './modules/qiime2/qiime2.nf'
include { VSearchCluster } from './modules/qiime2/qiime2.nf'

// Qiime2 Common Workflows Assign Sequence
include { TOOL_EXPORT as FeatureTableExport } from './modules/qiime2/qiime2_exports.nf'
include { TOOL_EXPORT as RepSeqExport } from './modules/qiime2/qiime2_exports.nf'
include { BIOM_TSV as FeatureTabToTSV } from './modules/qiime2/qiime2_exports.nf'

// Qiime2 Downstream Analysis
include { GENERATE_TREE } from './modules/qiime2/phylogeny.nf'
include { TOOL_EXPORT as RootTreeExport } from './modules/qiime2/qiime2_exports.nf'
include { TOOL_EXPORT as UnrootTreeExport } from './modules/qiime2/qiime2_exports.nf'
include { PHYLOGENEY_METRICS } from './modules/qiime2/phylogeny.nf'
include { ALPHA_DIV } from './modules/qiime2/diversity_inference.nf'
include { BETA_DIV } from './modules/qiime2/diversity_inference.nf'

// Call Workflows 
include { VisualSummary } from './modules/sub_workflows/visual_summary_subflow.nf'
include { SequenceAssign } from './modules/sub_workflows/assign_silva_taxa_subflow.nf'

// Main Workflow
workflow {

    // Load QIIME2 Metadata-File
    sample_info_ch = Channel
        .fromPath("${params.absolute_path_to_project}/${params.qiime2_metadata}")
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
        | FASTQC_RAW

    // Compile the Multi-QC Reports
    fastqc_raw_ch.collect() | MULTIQC_RAW

    // Run CUTADAPT for quality and length trimming
    trimmed_reads_ch = raw_reads_ch.map { sampleid, reads ->
        tuple(sampleid, reads, params.filtered_fastq_dir)
    }
        | CUTADAPT_QT

    // Update Metadata Columns to point to filtered files
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

    // Catch the updated metadata file
    qiime_updated_metadata_file = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) }

    // Export the file to a chanel
    qiime_updated_metadata_ch = qiime_updated_metadata_file.collect()

    // Run FASTQC on Filtered reads
    fastqc_filtered_ch = trimmed_reads_ch.map { sampleid, r1_filtered, r2_filtered ->
        tuple(sampleid, [r1_filtered, r2_filtered], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED

    // Compile the Multi-QC Reports
    fastqc_filtered_ch.collect() | MULTIQC_FILTERED

    // Create Qiime2Metadata
    UpdatedQiime2Metadata.map { metadataFile -> tuple(file(metadataFile), "metadata.qzv") } | TabulateMetadata

    // Import Reads to QZA
    Qiime2Reads_ch = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) } | Qiime2ImportReads

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
    SequenceAssign(asv_otu_common_ch)
}
