
include { FeatureTableSummary } from '../qiime2/qiime2.nf'
include { RepSeqTableSummary } from './../qiime2/qiime2.nf'

workflow VisualSummary {
    take:
    data_ch

    main:

    // Feature Table Summary
    data_ch.map { identifier, table_qza, rep_seqs, metadata ->
        tuple(identifier, file(table_qza), file(metadata))
    }
        | FeatureTableSummary

    // Rep. Sequence Summary
    data_ch.map { identifier, table_qza, rep_seqs, metadata -> tuple(identifier, file(rep_seqs)) } | RepSeqTableSummary
}
