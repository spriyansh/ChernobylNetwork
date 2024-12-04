// modules/qiime2/phylogeny.nf

process GenerateTree {
    tag "Phylogeny-ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_downstream_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(rep_seq_qza)

    output:
    tuple file("${identifier}-aligned-rep-seqs.qza"), file("${identifier}-masked-aligned-rep-seqs.qza"), file("${identifier}-unrooted-tree.qza"), file("${identifier}-rooted-tree.qza")

    script:
    """
    qiime phylogeny align-to-tree-mafft-fasttree --i-sequences ${rep_seq_qza} --o-alignment ${identifier}-aligned-rep-seqs.qza --o-masked-alignment ${identifier}-masked-aligned-rep-seqs.qza --o-tree ${identifier}-unrooted-tree.qza --o-rooted-tree ${identifier}-rooted-tree.qza
    """
}

process PhylogenyMetric {
    tag "Phylogeny-ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_downstream_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(feature_table_qza), file(rooted_tree_qza), file(metadata_tsv)

    output:
    path "${identifier}-core-metrics-results"

    script:
    """
    qiime diversity core-metrics-phylogenetic --i-phylogeny ${rooted_tree_qza} --i-table ${feature_table_qza} --p-sampling-depth ${params.phylogeny_sampling_depth} --m-metadata-file ${metadata_tsv} --output-dir ${identifier}-core-metrics-results
    """
}