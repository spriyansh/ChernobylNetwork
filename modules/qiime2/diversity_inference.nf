// modules/qiime2/diversity_inference.nf

process ALPHA_DIV {
    tag "QIIME2-Downstream"
    publishDir "${params.output_dir}/${params.qiime2_downstream_dir}/AlphaDiversity", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(faith_pd_vec), file(qiime_metadata_file)

    output:
    file "faith-pd-group-significance.qzv"

    script:
    """
    qiime diversity alpha-group-significance --i-alpha-diversity ${faith_pd_vec} --m-metadata-file ${qiime_metadata_file} --o-visualization faith-pd-group-significance.qzv
    """
}

process BETA_DIV {
    tag "QIIME2-Downstream"
    publishDir "${params.output_dir}/${params.qiime2_downstream_dir}/BetaDiversity", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(unw_dist_mat), file(qiime_metadata_file)

    output:
    file "unweighted-unifrac-group-significance.qzv"

    script:
    """
    qiime diversity beta-group-significance --i-distance-matrix ${unw_dist_mat} --m-metadata-file ${qiime_metadata_file} --m-metadata-column ${params.beta_div_col_name} --p-pairwise --o-visualization unweighted-unifrac-group-significance.qzv
    """
}
