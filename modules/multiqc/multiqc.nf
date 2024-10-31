process MULTIQC {
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path fastqc_results

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc ${fastqc_results} -o ./
    """
}
