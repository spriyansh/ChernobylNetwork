//modules/python/update_metadata.nf
process UPDATE_METADATA_COL {
    tag "Add Filtered Paths"
    publishDir "${params.output_dir}/${params.qiime2_main_dir}", mode: 'copy'
    conda params.pandas_numpy_conda_env

    input:
    tuple path(metadata_file), val(out_metadata_file), val(r1_col), val(r2_col), val(preceed_string)

    output:
    file "Qiime2MetadataInput.tsv"

    script:
    """
    python3 ${projectDir}/bin/update_metadata.py ${metadata_file} ${out_metadata_file} ${r1_col} ${r2_col} ${preceed_string}
    """
}
