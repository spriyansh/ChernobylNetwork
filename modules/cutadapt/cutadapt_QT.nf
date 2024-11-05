// modules/cutadapt/cutadapt_QT.nf
process CUTADAPT_QT {
    tag "${sampleid}"
    publishDir "${params.absolute_path_to_project}/${params.out_dir}/${filtered_dir}", mode: 'copy'
    conda params.cutadapt_conda_env

    input:
    tuple val(sampleid), path(reads), val(filtered_dir)

    output:
    tuple val(sampleid), path("${sampleid}_R1_filtered.fastq.gz"), path("${sampleid}_R2_filtered.fastq.gz")

    script:
    """
    cutadapt -u ${params.filter_trunc_length} -U ${params.filter_trunc_length} -m ${params.filter_min_length} -M ${params.filter_max_length} -q ${params.filter_quality_cutOff} -o ${sampleid}_R1_filtered.fastq.gz -p ${sampleid}_R2_filtered.fastq.gz ${reads[0]} ${reads[1]}
    """
}
