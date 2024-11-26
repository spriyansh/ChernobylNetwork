

## MOTHUR home="/home/spriyansh29/Projects/Chernobyl_Network_Nextflow/MOTHUR_TESTING"

## Create Contrigs
mothur "#make.contigs(file=M)"

## Screen-Seqs
mothur "#screen.seqs(fasta=Mtrim.contigs.fasta, count=Mcontigs.count_table, maxambig=0, maxlength=275, maxhomop=8)"

## Generic Summary Output
mothur "#summary.seqs(fasta=Mtrim.contigs.good.fasta, count=Mcontigs.good.count_table)" > screen.summary.txt

## Generate Unique Sequences
mothur "#unique.seqs(fasta=Mtrim.contigs.good.fasta, count=Mcontigs.good.count_table)"

## Ref Align
mothur "#align.seqs(fasta=Mtrim.contigs.good.unique.fasta, reference=silva.gold.align)"