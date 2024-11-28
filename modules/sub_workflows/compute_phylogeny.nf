include { GenerateTree } from '../qiime2/phylogeny.nf'
include { PhylogenyMetric } from '../qiime2/phylogeny.nf'

workflow Phylogeny {
    take:
    data_ch

    main:

    // Compute Phylogenetic-tree
    tree_ch = data_ch.map { taxa, identifier, table_qza, rep_seqs, metadata -> tuple(identifier, file(rep_seqs)) }
        | GenerateTree
        | merge(data_ch)

    // Compute Phylogenetic Metrics
    phylo_metric_ch = tree_ch.map { aligned_rep_seqs, masked_align_rep_seqs, unrooted_tree, rooted_tree, taxa, identifier, table_qza, rep_seqs, metadata ->
        tuple(identifier, table_qza, rooted_tree, metadata)
    }
        | PhylogenyMetric
        | collect
}
