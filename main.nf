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
include { BIOM_TSV as FeatureTabToTSV } from './modules/qiime2/qiime2_exports.nf'

// Call Workflows 
include { VisualSummary as ASV_Summary } from './modules/sub_workflows/visual_summary_subflow.nf'
include { VisualSummary as OTU_Summary } from './modules/sub_workflows/visual_summary_subflow.nf'
include { SequenceAssign as ASV_AssignTaxa } from './modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { SequenceAssign as OTU_AssignTaxa } from './modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { ExportData as ASV_Export } from './modules/sub_workflows/export_tables_subflow.nf'
include { ExportData as OTU_Export } from './modules/sub_workflows/export_tables_subflow.nf'
include { Phylogeny as ASV_Phylogeny } from './modules/sub_workflows/compute_phylogeny.nf'
include { Phylogeny as OTU_Phylogeny } from './modules/sub_workflows/compute_phylogeny.nf'

// Copy Output to S3 Buckets
include { CopyLocalToS3Bucket as OTU_S3_Table } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as OTU_S3_RepSeq } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as ASV_S3_Table } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as ASV_S3_RepSeq } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as Qiime2_S3_Metadata } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as Silva_S3_Classifier } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as Silva_S3_Seq } from './modules/aws_s3/s3_copy.nf'
include { CopyLocalToS3Bucket as Silva_S3_Taxanomy } from './modules/aws_s3/s3_copy.nf'

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
        | FASTQC_RAW

    // Compile the Multi-QC Reports
    fastqc_raw_ch.collect() | MULTIQC_RAW

    // Run CUTADAPT for quality and length trimming
    trimmed_reads_ch = raw_reads_ch.map { sampleid, reads ->
        tuple(sampleid, reads, params.filtered_fastq_dir)
    }
        | CUTADAPT_QT

    // Update Metadata Columns to point to filtered files
    qiime_metadata_file = file("${params.qiime2_metadata}")
    UpdatedQiime2Metadata = UpdateFilteredReads(
        tuple(
            qiime_metadata_file,
            "Qiime2MetadataInput.tsv",
            "r1_absolute",
            "r2_absolute",
            "${params.output_dir}/${params.filtered_fastq_dir}"
        )
    )

    // Run FASTQC on Filtered reads
    fastqc_filtered_ch = trimmed_reads_ch.map { sampleid, r1_filtered, r2_filtered ->
        tuple(sampleid, [r1_filtered, r2_filtered], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED

    // Compile the Multi-QC Reports
    pre_process_ch = fastqc_filtered_ch.collect() | MULTIQC_FILTERED

    // Catch the updated metadata file
    qiime_updated_metadata_file = UpdatedQiime2Metadata.map { metadataFile -> metadataFile }.collect()

    // Create Metadata Ch
    qiime_updated_metadata_file
        .combine(
            pre_process_ch
        )
        .set { tmp }
    metadata_ch = tmp.map { it.first() }

    // Create Qiime2Metadata
    metadata_ch.map { metadataFile -> tuple(file(metadataFile), "metadata.qzv") } | TabulateMetadata

    // Combine trimmed reads and metadata, set as tmp_ch
    tmp_ch = trimmed_reads_ch.combine(UpdatedQiime2Metadata)

    // Import Reads to QZA
    Qiime2Reads_ch = metadata_ch.map { metadataFile -> file(metadataFile) } | Qiime2ImportReads

    // Summarize
    Qiime2Reads_ch.map { demux_reads_qza -> file(demux_reads_qza) } | Qiime2SummaryToQVZ

    // Deionize-DADA2
    DADA2_Denoised_ch = Qiime2Reads_ch.map { demux_qza -> file(demux_qza) } | DADA2Denoise

    // Combine DADA2_Denoised_ch with Metadata file channel
    DADA2_Denoised_ch
        .combine(metadata_ch)
        .set { Qiime2Denoise_ch }

    // Summarize Denoise Statistics
    Qiime2Denoise_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(file(denoise_stats), "dada2-denoising-stats.qzv") } | TabulateDenoiseStats

    // Compute OTUs
    VCluster_ch = Qiime2Denoise_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(table_qza, rep_seqs) } | VSearchCluster

    // Combine with metadata
    VCluster_ch
        .combine(metadata_ch)
        .set { Qiime2_Cluster_ch }

    // Prepare Common Chanels
    asv_chanel = Qiime2Denoise_ch.map { table_qza, repSeq_qza, rm_denoise_stats, metadata ->
        tuple('ASV', table_qza, repSeq_qza, metadata)
    }
    otu_chanel = Qiime2_Cluster_ch.map { table_qza, repSeq_qza, rm_new_seqs, metadata ->
        tuple('OTU', table_qza, repSeq_qza, metadata)
    }

    // Generate Visual Summaries
    asv_chanel | ASV_Summary
    otu_chanel | OTU_Summary

    // Validate
    if (params.export_to_s3) {
        otu_chanel.map { label, table_qza, repSeq_qza, metadata -> tuple(table_qza, "OTU") } | OTU_S3_Table
        otu_chanel.map { label, table_qza, repSeq_qza, metadata -> tuple(repSeq_qza, "OTU") } | OTU_S3_RepSeq
        asv_chanel.map { label, table_qza, repSeq_qza, metadata -> tuple(table_qza, "ASV") } | ASV_S3_Table
        asv_chanel.map { label, table_qza, repSeq_qza, metadata -> tuple(repSeq_qza, "ASV") } | ASV_S3_RepSeq
        asv_chanel.map { label, table_qza, repSeq_qza, metadata -> tuple(file(metadata), ".") } | Qiime2_S3_Metadata

        Channel.fromPath(params.qiime2_silva_trained_classfier).map { silva_classifier_qza -> tuple(silva_classifier_qza, "MicrobialData_DBs") } | Silva_S3_Classifier
        Channel.fromPath(params.qiime2_silva_dna_seq).map { silva_seq_qza -> tuple(silva_seq_qza, "MicrobialData_DBs") } | Silva_S3_Seq
        Channel.fromPath(params.qiime2_silva_taxa).map { silva_taxa_tsv -> tuple(silva_taxa_tsv, "MicrobialData_DBs") } | Silva_S3_Taxanomy
    }

    if (params.perform_downstream_steps) {
        // AssignTaxa from SilvaDB
        asv_taxa_ch = asv_chanel | ASV_AssignTaxa
        otu_taxa_ch = otu_chanel | OTU_AssignTaxa

        // Export Data
        asv_taxa_ch | ASV_Export
        otu_taxa_ch | OTU_Export

        // Compute Phylogeny
        asv_taxa_ch | ASV_Phylogeny
        otu_taxa_ch | OTU_Phylogeny
    }
}
