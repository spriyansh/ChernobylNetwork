// modules/fastqc/fastqc.nf

process FASTQC {
    tag "${sample_id}"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    file "*_fastqc.{zip,html}"

    script:
    """
    fastqc ${reads[0]} --outdir ./
    fastqc ${reads[1]} --outdir ./
    """
}
