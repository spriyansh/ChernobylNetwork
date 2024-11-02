// Sample Command cutadapt   --quality-cutoff=20   -m 36   -o filtered_R1.fastq.gz -p filtered_R2.fastq.gz   ../RawSeqDataTest/1-1-1_TAAGGCGA-CTCTCTAT_L001_R1_001.fastq.gz ../RawSeqDataTest/1-1-1_TAAGGCGA-CTCTCTAT_L001_R2_001.fastq.gz

// modules/cutadapt/cutadapt_QT.nf
process CUTADAPT_QT {
    tag "${sample_id}"
    publishDir "${params.out_dir}/${filtered_dir}", mode: 'copy'

    input:
    tuple val(sample_id), path(reads), val(filtered_dir)

    output:
    tuple val(sample_id), path("${sample_id}_R1_filtered.fastq.gz"), path("${sample_id}_R2_filtered.fastq.gz")

    script:
    """
    cutadapt --cores=${task.cpus} --quality-cutoff=${params.filter_cutOff} -m ${params.filter_min_length} -o ${sample_id}_R1_filtered.fastq.gz -p ${sample_id}_R2_filtered.fastq.gz ${reads[0]} ${reads[1]}
    """
}
