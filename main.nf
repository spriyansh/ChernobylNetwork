#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// FastQC & MultiQC Processes
include { FASTQC as FASTQC_RAW } from './modules/fastqc/fastqc.nf'
include { FASTQC as FASTQC_FILTERED } from './modules/fastqc/fastqc.nf'
include { CUTADAPT_QT } from './modules/cutadapt/cutadapt_QT.nf'
include { MULTIQC_RAW } from './modules/multiqc/multiqc.nf'
include { MULTIQC_FILTERED } from './modules/multiqc/multiqc.nf'

// QIIME2 Processes
include { QiimeTabulate as TabulateMetadata } from './modules/qiime2/qiime2.nf'
include { QiimeTabulate as TabulateDenoise } from './modules/qiime2/qiime2.nf'
include { UPDATE_METADATA_COL as UpdateFilteredReads } from './modules/python/update_metadata.nf'
include { QiimeImportReads } from './modules/qiime2/qiime2.nf'
include { Qiime2Denoise } from './modules/qiime2/qiime2.nf'
include { FeatureTableSummary } from './modules/qiime2/qiime2.nf'
include { FeatureTableTabulateSeq } from './modules/qiime2/qiime2.nf'
include { AssignSequence } from './modules/qiime2/qiime2.nf'
include { VisualizeTaxanomy } from './modules/qiime2/qiime2.nf'
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
    qiime_updated_metadata_file = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) }
    qiime_updated_metadata_ch = qiime_updated_metadata_file.collect()
    // qiime_updated_metadata_file.view()

    //Process filtered reads for FASTQC on Filtered Data
    fastqc_filtered_ch = trimmed_reads_ch.map { sampleid, r1_filtered, r2_filtered ->
        tuple(sampleid, [r1_filtered, r2_filtered], params.filtered_fastQC_dir)
    }
        | FASTQC_FILTERED
    fastqc_filtered_ch.collect() | MULTIQC_FILTERED

    // Create Qiime2Metdata
    tabulatedMetadata = UpdatedQiime2Metadata.map { metadataFile -> tuple(file(metadataFile), "metadata.qzv") } | TabulateMetadata

    // Import Data
    QiimeReads_ch = UpdatedQiime2Metadata.map { metadataFile -> file(metadataFile) } | QiimeImportReads

    // Deionize
    DeNoize_ch = QiimeReads_ch.map { demux_qza, demux_summary ->
        file(demux_qza)
    }
        | Qiime2Denoise


    DeNoize_ch
        .combine(qiime_updated_metadata_ch)
        .set { denoise_metadata_ch }

    // denoise_metadata_ch.view()

    // Create Visuals
    denoise_metadata_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(table_qza, metadata) } | FeatureTableSummary
    denoise_metadata_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> file(rep_seqs) } | FeatureTableTabulateSeq
    denoise_metadata_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> tuple(file(denoise_stats), "denoising-stats.qzv") } | TabulateDenoise

    // Assign Sequence
    taxonomy_ch = denoise_metadata_ch.map { table_qza, rep_seqs, denoise_stats, metadata -> rep_seqs } | AssignSequence

    taxonomy_ch_collect = taxonomy_ch.collect()
    viz_tax_input_ch = denoise_metadata_ch.map { denoise_tuple ->
        def taxonomy_file = taxonomy_ch_collect.val[0]
        return denoise_tuple + [taxonomy_file]
    }

    viz_tax_input_ch.map { table_qza, rep_seqs, denoise_stats, metadata, taxon_qza -> tuple(file(table_qza), file(taxon_qza), metadata) } | VisualizeTaxanomy

    // Export feature table to Biom Format
    feature_tab_biom_ch = DeNoize_ch.map { table_qza, rep_seqs, denoise_stats -> tuple(table_qza, "ASV_Feature_Table") } | FeatureTableExport
    taxonomy_ch.map { taxa_qza -> tuple(taxa_qza, "Rep_Sequences") } | RepSeqExport

    //     // Wait for the Feature Table export to biom and wait for the process end
    feature_table = "${params.output_dir}/${params.qiime2_exports_dir}/ASV_Feature_Table/feature-table.biom"
    feature_tab_biom_ch.collect().map { result -> file(feature_table) } | FeatureTabToTSV

    // Downstream Analysis
    phylogenetic_tree_ch = DeNoize_ch.map { table_qza, rep_seqs, denoise_stats -> file(rep_seqs) } | GENERATE_TREE
    phylogenetic_tree_ch.map { aligned_seqs_qza, masked_seq_qza, unrooted_tree_qza, rooted_tree_qza -> tuple(rooted_tree_qza, "Phylogeney/RootedTree") } | RootTreeExport
    phylogenetic_tree_ch.map { aligned_seqs_qza, masked_seq_qza, unrooted_tree_qza, rooted_tree_qza -> tuple(unrooted_tree_qza, "Phylogeney/UnrootedTree") } | UnrootTreeExport

    // Combine Specific Parts of the chanells
    denoise_metadata_ch
        .combine(phylogenetic_tree_ch)
        .map { combined_tuple ->
            def count_tab = combined_tuple[0]
            def metadata = combined_tuple[3]
            def rooted_tree = combined_tuple[7]
            return [count_tab, rooted_tree, metadata]
        }
        .set { phylo_metric_input }

    // // Compute Phylogenetic Metrics
    phylo_metric_ch = phylo_metric_input.map { count_tab, rooted_tree_qza, metadata -> tuple(count_tab, rooted_tree_qza, metadata) } | PHYLOGENEY_METRICS

    // // Compute Alpha Diversity
    // faith_pd_vec = "${params.output_dir}/${params.qiime2_downstream_dir}/core-metrics-results/faith_pd_vector.qza"
    // unw_dist_mat = "${params.output_dir}/${params.qiime2_downstream_dir}/core-metrics-results/unweighted_unifrac_distance_matrix.qza"


    phylo_metric_ch
        .combine(qiime_updated_metadata_ch)
        .set { diversity_ch }

        // diversity_ch.view()


    // diversity_ch.map { element ->
    //     tuple(file(faith_pd_vec), element[1])
    // }
    //     | ALPHA_DIV

    // diversity_ch.map { element ->
    //     tuple(file(unw_dist_mat), element[1])
    // }
    //     | BETA_DIV
}
