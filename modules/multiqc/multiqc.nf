// modules/multiqc/multiqc.nf
process MULTIQC_RAW {
    conda params.multiqc_conda_env

    input:
    path fastqc_raw_files

    output:
    file "multiqc_report.html"

    script:
    """
    multiqc ${params.output_dir}/${params.raw_fastQC_dir} -o .
    cp multiqc_report.html ${params.output_dir}/${params.raw_fastQC_dir}/multiqc_report.html
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
    multiqc --force ${params.output_dir}/${params.filtered_fastQC_dir} -o .
    cp multiqc_report.html ${params.output_dir}/${params.filtered_fastQC_dir}/multiqc_report.html
    """
}
