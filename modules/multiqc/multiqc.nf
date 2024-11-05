// modules/multiqc/multiqc.nf
process MULTIQC_RAW {
    conda params.multiqc_conda_env

    input:
    path fastqc_raw_files

    output:
    file "multiqc_report.html"

    script:
    """
    multiqc ${params.absolute_path_to_project}/${params.out_dir}/${params.raw_fastQC_dir} -o ./
    """
}

process MULTIQC_FILTERED {
    conda params.multiqc_conda_env

    input:
    path fastqc_filtered_files

    output:
    file "multiqc_report.html"

    script:
    """
    multiqc ${params.absolute_path_to_project}/${params.out_dir}/${params.filtered_fastQC_dir} ./
    """
}
