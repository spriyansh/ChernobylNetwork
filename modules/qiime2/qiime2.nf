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
