// modules/qiime2/qiime2.nf

process QiimeMetadataTabulate {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'move'
    conda params.qiime2_conda_env

    input:
    path qiime_metadata_file

    output:
    path "metadata.qzv"

    script:
    """
    mkdir -p ${params.output_dir}/${params.qiime2_QVZ_dir}
    qiime metadata tabulate --m-input-file ${qiime_metadata_file} --o-visualization metadata.qzv
    """
}

//// qiime metadata tabulate --m-input-file ${qiime_metadata_file} --o-visualization ${params.absolute_path_to_project}/${params.out_dir}/${params.qiime2_QVZ_dir}/metadata.qzv