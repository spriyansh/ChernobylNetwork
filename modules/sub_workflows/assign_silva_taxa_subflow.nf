include { AssignSilvaTaxa } from '../qiime2/qiime2.nf'
include { TaxaBars } from '../qiime2/qiime2.nf'

workflow SequenceAssign {
    take:
    data_ch

    main:

    // Feature Table Summary
    taxa_ch = data_ch.map { identifier, table_qza, rep_seqs, metadata ->
        tuple(identifier, file(rep_seqs))
    }
        | AssignSilvaTaxa

    // Merge outputs
    data_ch.merge(taxa_ch).set{data_taxa_ch}

    data_taxa_ch.map { identifier, table_qza, rep_seqs, metadata, tax ->
        tuple(identifier, file(table_qza), file(metadata), tax)
    }
        | TaxaBars
}
