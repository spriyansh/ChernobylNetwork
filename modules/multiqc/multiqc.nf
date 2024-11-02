// process MULTIQC {
//     publishDir "${params.out_dir}/${multiqc_dir}", mode: 'copy'

//     input:
//     tuple path(fastqc_results_dir), val(multiqc_dir)

//     output:
//     path "multiqc_report.html"

//     script:
//     """
//     multiqc ${params.out_dir}/${fastqc_results_dir} -o ./
//     """
// }

// process MULTIQC {
//     publishDir "${params.out_dir}/${fastqc_results_dir}", mode: 'copy'

//     input:
//     val fastqc_results_dir

//     output:
//     path "multiqc_report.html"

//     script:
//     """
//     multiqc ${params.out_dir}/${fastqc_results_dir} -o .
//     """
// }


process MULTIQC {
    publishDir "${params.out_dir}/${fastqc_results_dir}", mode: 'copy'

    input:
    val fastqc_results_dir

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc ${params.out_dir}/${fastqc_results_dir} -o ./
    """
}
