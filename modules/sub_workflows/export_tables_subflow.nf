include { Qiime2Export as featureExport } from '../qiime2/qiime2_exports.nf'
include { Qiime2Export as taxaExport } from '../qiime2/qiime2_exports.nf'
include { BIOM_TSV } from '../qiime2/qiime2_exports.nf'

workflow ExportData {
    take:
    data_ch

    main:

    // Extract Identifier val
    def idn = data_ch.map { taxa, identifier, table_qza, rep_seqs, metadata -> identifier }

    // Feature Table to Biom Format
    feature_tab_ch = data_ch.map {taxa, identifier, table_qza, rep_seqs, metadata -> tuple(identifier, "FeatureTable", table_qza) } | featureExport
    data_ch.map {taxa, identifier, table_qza, rep_seqs, metadata -> tuple(identifier, "Taxanomy", taxa) } | taxaExport

    // Export TSV
    BIOM_TSV(feature_tab_ch)
}
