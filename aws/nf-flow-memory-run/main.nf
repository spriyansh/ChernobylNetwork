// Call Workflows 
include { VisualSummary as ASV_Summary } from './../../modules/sub_workflows/visual_summary_subflow.nf'
include { VisualSummary as OTU_Summary} from './../../modules/sub_workflows/visual_summary_subflow.nf'
include { SequenceAssign as ASV_AssignTaxa} from './../../modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { SequenceAssign as OTU_AssignTaxa} from './../../modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { ExportData as ASV_Export} from './../../modules/sub_workflows/export_tables_subflow.nf'
include { ExportData as OTU_Export} from './../../modules/sub_workflows/export_tables_subflow.nf'
include { Phylogeny as ASV_Phylogeny} from './../../modules/sub_workflows/compute_phylogeny.nf'
include { Phylogeny as OTU_Phylogeny} from './../../modules/sub_workflows/compute_phylogeny.nf'

workflow {
    // Common Metadata
    metadata = Channel.fromPath("../../../Nextflow_Output/Qiime2Data/Qiime2MetadataInput.tsv")

    // Read Files for asv
    table_asv = Channel.fromPath("../../../Nextflow_Output/Qiime2Data/Qiime2_QZA/dada2-table.qza")
    repseq_asv = Channel.fromPath("../../../Nextflow_Output/Qiime2Data/Qiime2_QZA/dada2-rep-seqs.qza")

    // Read Tables for otu
    table_otu = Channel.fromPath("../../../Nextflow_Output/Qiime2Data/Qiime2_QZA/vcluster-open-ref-table.qza")
    repseq_otu = Channel.fromPath("../../../Nextflow_Output/Qiime2Data/Qiime2_QZA/vcluster-open-ref-rep-seqs.qza")

    // Combine to make channels
    // ASVs
    asv_chanel = Channel
        .of("ASV")
        .combine(table_asv)
        .combine(repseq_asv)
        .combine(metadata)

    // OTUs
    otu_chanel = Channel
        .of("OTU")
        .combine(table_otu)
        .combine(repseq_otu)
        .combine(metadata)

    // Generate Visual Summaries
    asv_chanel | ASV_Summary
    otu_chanel | OTU_Summary

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