// Import process 
include { SequenceAssign as ASV_AssignTaxa } from './../../modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { SequenceAssign as OTU_AssignTaxa } from './../../modules/sub_workflows/assign_silva_taxa_subflow.nf'
include { ExportData as ASV_Export } from './../../modules/sub_workflows/export_tables_subflow.nf'
include { ExportData as OTU_Export } from './../../modules/sub_workflows/export_tables_subflow.nf'
include { Phylogeny as ASV_Phylogeny } from './../../modules/sub_workflows/compute_phylogeny.nf'
include { Phylogeny as OTU_Phylogeny } from './../../modules/sub_workflows/compute_phylogeny.nf'

workflow {

    // Metadata
    metadata = Channel.fromPath("${params.s3_data}/Qiime2MetadataInput.tsv")

    // ASVs
    table_asv = Channel.fromPath("${params.s3_data}/ASV/dada2-table.qza")
    repseq_asv = Channel.fromPath("${params.s3_data}/ASV/dada2-rep-seqs.qza")

    // OTUs
    table_otu = Channel.fromPath("${params.s3_data}/OTU/vcluster-open-ref-table.qza")
    repseq_otu = Channel.fromPath("${params.s3_data}/OTU/vcluster-open-ref-rep-seqs.qza")

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

    otu_chanel.view()
    asv_chanel.view()

    // AssignTaxa from SilvaDB
    asv_taxa_ch = asv_chanel | ASV_AssignTaxa
    otu_taxa_ch = otu_chanel | OTU_AssignTaxa
}