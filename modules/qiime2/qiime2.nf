// modules/qiime2/qiime2.nf

// Tabulate Metadata
process QiimeMetadataTabulate {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file qiime_metadata_file

    output:
    file "metadata.qzv"

    script:
    """
    qiime metadata tabulate --m-input-file ${qiime_metadata_file} --o-visualization metadata.qzv
    """
}

// Tabulate Metadata
process QiimeImportReads {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file qiime_metadata_file

    output:
    tuple file("demux-paired-end.qza"), file("demux-summary.qzv")

    script:
    """
    qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ${qiime_metadata_file} --input-format PairedEndFastqManifestPhred33V2 --output-path demux-paired-end.qza
    qiime demux summarize --i-data demux-paired-end.qza --o-visualization demux-summary.qzv
    """
}

// Deionize
process Qiime2DeIonize {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file demux_qza

    output:
    tuple file("table.qza"), file("rep-seqs.qza"), file("denoising-stats.qza")

    script:
    """
    qiime dada2 denoise-paired --i-demultiplexed-seqs ${demux_qza} --p-trunc-len-f ${params.trunc_length_f} --p-trunc-len-r ${params.trunc_length_r} --o-table table.qza --o-representative-sequences rep-seqs.qza --o-denoising-stats denoising-stats.qza
    """
}

// Create Visuals for the table
process FeatureTableSummary {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(table_qza), file(metadata_tsv)

    output:
    file "table-summary.qzv"

    script:
    """
    qiime feature-table summarize --i-table ${table_qza} --o-visualization table-summary.qzv --m-sample-metadata-file ${metadata_tsv}
    """
}

process FeatureTableTabulateSeq {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file rep_seqs_qza

    output:
    file "rep-seqs-summary.qzv"

    script:
    """
    qiime feature-table tabulate-seqs --i-data ${rep_seqs_qza} --o-visualization rep-seqs-summary.qzv
    """
}

process DeionizeStatTabulate {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file denoising_stats_qza

    output:
    file "denoising-stats.qzv"

    script:
    """
    qiime metadata tabulate --m-input-file ${denoising_stats_qza} --o-visualization denoising-stats.qzv
    """
}
