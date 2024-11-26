// modules/qiime2/qiime2_export.nf

process TOOL_EXPORT {
    tag "QIIME2-Export"
    publishDir "${params.output_dir}/${params.qiime2_exports_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(in_file), val(out_folder_name)

    output:
    path "${out_folder_name}"

    script:
    """
    qiime tools export --input-path ${in_file} --output-path "${out_folder_name}"
    """
}

process BIOM_TSV {
    tag "BIOM-Convert"
    publishDir "${params.output_dir}/${params.qiime2_exports_dir}/ASV_Feature_Table/", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file biom_file

    output:
    file "feature-table.tsv"

    script:
    """
    biom convert -i ${biom_file} -o feature-table.tsv --to-tsv
    """
}
