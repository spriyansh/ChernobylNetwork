// modules/cutadapt/cutadapt_QT.nf
process CUTADAPT_QT {
    tag "${sampleid}"
    publishDir "${params.output_dir}/${filtered_dir}", mode: 'copy'
    conda params.cutadapt_conda_env

    input:
    tuple val(sampleid), path(reads), val(filtered_dir)

    output:
    tuple val(sampleid), file("${sampleid}_filtered_R1.fastq.gz"), file("${sampleid}_filtered_R2.fastq.gz")

    script:
    """
    cutadapt --trim-n -u ${params.filter_trunc_length} -U ${params.filter_trunc_length} -m ${params.filter_min_length} -M ${params.filter_max_length} -q ${params.filter_quality_cutOff} -o ${sampleid}_filtered_R1.fastq.gz -p ${sampleid}_filtered_R2.fastq.gz ${reads[0]} ${reads[1]}
    """
}