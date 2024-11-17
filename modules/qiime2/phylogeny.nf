// modules/qiime2/phylogeny.nf

process GENERATE_TREE {
    tag "QIIME2-Downstream"
    publishDir "${params.output_dir}/${params.qiime2_downstream_dir}/Phylogeny", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file rep_seq_qza

    output:
    tuple file("aligned-rep-seqs.qza"), file("masked-aligned-rep-seqs.qza"), file("unrooted-tree.qza"), file("rooted-tree.qza")

    script:
    """
    qiime phylogeny align-to-tree-mafft-fasttree --i-sequences ${rep_seq_qza} --o-alignment aligned-rep-seqs.qza --o-masked-alignment masked-aligned-rep-seqs.qza --o-tree unrooted-tree.qza --o-rooted-tree rooted-tree.qza
    """
}
