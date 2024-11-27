// modules/qiime2/qiime2_export.nf

process Qiime2Export {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_exports_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), val(out_folder_name), file(in_file)

    output:
    path "${identifier}-${out_folder_name}"

    script:
    """
    qiime tools export --input-path ${in_file} --output-path "${identifier}-${out_folder_name}"
    """
}

process BIOM_TSV {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_exports_dir}/${folder_name}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    path folder_name

    output:
    file "feature-table.tsv"

    script:
    """
    biom convert -i ${folder_name}/feature-table.biom -o feature-table.tsv --to-tsv
    """
}
