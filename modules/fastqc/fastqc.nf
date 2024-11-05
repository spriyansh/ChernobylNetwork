// modules/fastqc/fastqc.nf

process FASTQC {
    tag "${sampleid}"
    publishDir "${params.absolute_path_to_project}/${params.out_dir}/${fastqc_dir}", mode: 'copy'
    conda params.fastqc_conda_env 

    input:
    tuple val(sampleid), path(reads), val(fastqc_dir)

    output:
    file "*_fastqc.{zip,html}"

    script:
    """
    fastqc ${reads[0]} --outdir ./
    fastqc ${reads[1]} --outdir ./
    """
}
