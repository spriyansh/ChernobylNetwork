include { AssignSilvaTaxa } from '../qiime2/qiime2.nf'
include { TaxaBars } from '../qiime2/qiime2.nf'

workflow SequenceAssign {
    take:
    data_ch

    main:

    // Feature Table Summary
    data_taxa_ch = data_ch.map { identifier, table_qza, rep_seqs, metadata ->
        tuple(identifier, file(rep_seqs))
    }
        | AssignSilvaTaxa
        | merge(data_ch)

    // Taxa Bar
    taxa_bar_ch = data_taxa_ch.map { tax, identifier, table_qza, rep_seqs, metadata ->
        tuple(identifier, file(table_qza), file(metadata), tax)
    }
        | TaxaBars
        | collect

    emit:
    data_taxa_ch
}
