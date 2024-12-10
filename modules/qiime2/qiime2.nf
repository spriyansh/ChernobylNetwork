// modules/qiime2/qiime2.nf

// Tabulate Metadata
process Qiime2Tabulate {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(qiime_metadata_file), val(out_file_name)

    output:
    file "${out_file_name}"

    script:
    """
    qiime metadata tabulate --m-input-file ${qiime_metadata_file} --o-visualization ${out_file_name}
    """
}

// Import Reads
process Qiime2ImportReads {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file qiime_metadata_file

    output:
    file "demux-paired-end.qza"

    script:
    """
    qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ${qiime_metadata_file} --input-format PairedEndFastqManifestPhred33V2 --output-path demux-paired-end.qza
    """
}

// Visual Summary of QZA
process Qiime2SummaryToQVZ {
    tag "Qiime2"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file demux_reads_qza

    output:
    file "demux-summary.qzv"

    script:
    """
    qiime demux summarize --i-data ${demux_reads_qza} --o-visualization demux-summary.qzv
    """
}

// Denoize
process DADA2Denoise {
    tag "DADA2-ASVs"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    file demux_qza

    output:
    tuple file("dada2-table.qza"), file("dada2-rep-seqs.qza"), file("dada2-denoising-stats.qza")

    script:
    """
    qiime dada2 denoise-paired --i-demultiplexed-seqs ${demux_qza} --p-trunc-len-f ${params.trunc_length_f} --p-trunc-len-r ${params.trunc_length_r} --p-trim-left-f ${params.trim_length_f} --p-trim-left-r ${params.trim_length_r} --p-max-ee-f ${params.max_ee_f} --p-max-ee-r ${params.max_ee_r} --o-table dada2-table.qza --o-representative-sequences dada2-rep-seqs.qza --o-denoising-stats dada2-denoising-stats.qza
    """
}

// Generate OTUs
process VSearchCluster {
    tag "VSearch-OTU-97"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple file(table_qza), file(rep_seqs_qza)

    output:
    tuple file("vcluster-open-ref-table.qza"), file("vcluster-open-ref-rep-seqs.qza"), file("vcluster-open-ref-new-seqs.qza")

    script:
    """
    qiime vsearch cluster-features-open-reference --i-sequences ${rep_seqs_qza} --i-table ${table_qza} --p-perc-identity 0.97 --i-reference-sequences ${params.qiime2_silva_dna_seq} --o-clustered-table vcluster-open-ref-table.qza --o-clustered-sequences vcluster-open-ref-rep-seqs.qza --o-new-reference-sequences vcluster-open-ref-new-seqs.qza
    """
}

// Create Visuals for the table
process FeatureTableSummary {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(table_qza), file(metadata_tsv)

    output:
    file "${identifier}-table-summary.qzv"

    script:
    """
    qiime feature-table summarize --i-table ${table_qza} --o-visualization ${identifier}-table-summary.qzv --m-sample-metadata-file ${metadata_tsv}
    """
}

// Rep. Sequence Summary
process RepSeqTableSummary {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(rep_seqs_qza)

    output:
    file "${identifier}-rep-seqs-summary.qzv"

    script:
    """
    qiime feature-table tabulate-seqs --i-data ${rep_seqs_qza} --o-visualization ${identifier}-rep-seqs-summary.qzv
    """
}

// Fit Naive Bayes
process AssignSilvaTaxa {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_QZA_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(rep_seq_qza)

    output:
    file "${identifier}-taxonomy.qza"

    script:
    """
    qiime feature-classifier classify-sklearn --i-classifier ${params.qiime2_silva_trained_classfier} --i-reads ${rep_seq_qza} --o-classification ${identifier}-taxonomy.qza
    """
}

// Visualize Taxanomy
process TaxaBars {
    tag "ASV-OTU"
    publishDir "${params.output_dir}/${params.qiime2_QVZ_dir}", mode: 'copy'
    conda params.qiime2_conda_env

    input:
    tuple val(identifier), file(table_qza), file(metadata_tsv), file(taxa_qza)

    output:
    file "${identifier}-taxa-bar-plots.qzv"

    script:
    """
    qiime taxa barplot --i-table ${table_qza} --i-taxonomy ${taxa_qza} --m-metadata-file ${metadata_tsv} --o-visualization ${identifier}-taxa-bar-plots.qzv
    """
}
