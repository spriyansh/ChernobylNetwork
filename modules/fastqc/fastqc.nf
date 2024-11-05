// modules/fastqc/fastqc.nf

process FASTQC {
    tag "${sampleid}"
    publishDir "${params.output_dir}/${fastqc_dir}", mode: 'move'
    conda params.fastqc_conda_env 

    input:
    tuple val(sampleid), path(reads), val(fastqc_dir)

    output:
    file "*_fastqc.{zip,html}"

    script:
    """
    fastqc ${reads[0]}
    fastqc ${reads[1]}
    """
}
