include { GenerateTree } from '../qiime2/phylogeny.nf'
include { PhylogenyMetric } from '../qiime2/phylogeny.nf'

workflow Phylogeny {
    take:
    data_ch

    main:

    // Compute Phylogenetic-tree
    tree_ch = data_ch.map { identifier, table_qza, rep_seqs, metadata, taxa -> tuple(identifier, file(rep_seqs)) } | GenerateTree

    // Merge the tree_ch and data_ch
    data_ch.merge(tree_ch).set { data_phylo }

    // Compute Phylogenetic Metrics
    phylo_metric_ch = data_phylo.map { identifier, table_qza, rep_seqs, metadata, taxa, aligned_rep_seqs, masked_align_rep_seqs, unrooted_tree, rooted_tree ->
        tuple(identifier, table_qza, rooted_tree, metadata)
    }
        | PhylogenyMetric
}
