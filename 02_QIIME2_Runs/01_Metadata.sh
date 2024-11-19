# Create and Validate metadata
qiime metadata tabulate --m-input-file ProcessedData/Qiime2Metadata.tsv --o-visualization QIIME2Data/metadata.qzv

# Import
qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path ProcessedData/Qiime2Metadata.tsv --input-format PairedEndFastqManifestPhred33V2 --output-path QIIME2Data/demux-paired-end.qza

# Summarize
qiime demux summarize --i-data QIIME2Data/demux-paired-end.qza --o-visualization QIIME2Data/demux-summary.qzv

# Deionize
qiime dada2 denoise-paired --i-demultiplexed-seqs QIIME2Data/demux-paired-end.qza --p-trunc-len-f 230 --p-trunc-len-r 200 --o-table QIIME2Data/table.qza --o-representative-sequences QIIME2Data/rep-seqs.qza --o-denoising-stats QIIME2Data/denoising-stats.qza

# Create Visuals
qiime feature-table summarize --i-table QIIME2Data/table.qza --o-visualization QIIME2Data/table-summary.qzv --m-sample-metadata-file ProcessedData/Qiime2Metadata.tsv
qiime feature-table tabulate-seqs --i-data QIIME2Data/rep-seqs.qza --o-visualization QIIME2Data/rep-seqs-summary.qzv
qiime metadata tabulate --m-input-file QIIME2Data/denoising-stats.qza --o-visualization QIIME2Data/denoising-stats.qzv

# Train with classifier
qiime feature-classifier fit-classifier-naive-bayes --i-reference-reads MicrobialData/SILVA_138/silva-138-99-seqs-515-806.qza --i-reference-taxonomy MicrobialData/SILVA_138/silva-138-99-tax-515-806.qza --o-classifier QIIME2Data/silva-138-99-515-806-classifier.qza

# Assign Sequence
qiime feature-classifier classify-sklearn --i-classifier QIIME2Data/silva-138-99-515-806-classifier.qza --i-reads QIIME2Data/rep-seqs.qza --o-classification QIIME2Data/taxonomy.qza

# Visualize Assigned Taxanomy
qiime taxa barplot --i-table QIIME2Data/table.qza –i-taxonomy QIIME2Data/taxonomy.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --o-visualization QIIME2Data/taxa-bar-plots.qzv

# Exporting Data for Further Analysis
# Export data to a folder
qiime tools export --input-path QIIME2Data/table.qza --output-path QIIME2Data/ExportedData/table
biom convert -i QIIME2Data/ExportedData/table/feature-table.biom -o QIIME2Data/ExportedData/table/feature-table.tsv --to-tsv
qiime tools export --input-path QIIME2Data/taxonomy.qza --output-path QIIME2Data/ExportedData/taxonomy

# Downstream Analysis

# Create a rooted phylogenetic tree (necessary for phylogenetic metrics)
qiime phylogeny align-to-tree-mafft-fasttree --i-sequences QIIME2Data/rep-seqs.qza --o-alignment QIIME2Data/aligned-rep-seqs.qza --o-masked-alignment QIIME2Data/masked-aligned-rep-seqs.qza --o-tree QIIME2Data/unrooted-tree.qza --o-rooted-tree QIIME2Data/rooted-tree.qza
qiime tools export --input-path QIIME2Data/rooted-tree.qza --output-path QIIME2Data/ExportedData/tree
qiime diversity core-metrics-phylogenetic --i-phylogeny QIIME2Data/rooted-tree.qza --i-table QIIME2Data/table.qza --p-sampling-depth 10000 --m-metadata-file ProcessedData/Qiime2Metadata.tsv --output-dir QIIME2Data/core-metrics-results

# Alpha Diversity Visualizations
qiime diversity alpha-group-significance --i-alpha-diversity QIIME2Data/core-metrics-results/faith_pd_vector.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --o-visualization QIIME2Data/core-metrics-results/faith-pd-group-significance.qzv

# Beta Diversity Visualizations (PCA, PCoA plots)
qiime diversity beta-group-significance --i-distance-matrix QIIME2Data/core-metrics-results/unweighted_unifrac_distance_matrix.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --m-metadata-column Impact --o-visualization QIIME2Data/core-metrics-results/unweighted-unifrac-group-significance.qzv --p-pairwise

# Alpha and Beta Diversity Correlation Analysis
qiime diversity alpha-correlation --i-alpha-diversity QIIME2Data/core-metrics-results/shannon_vector.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --o-visualization QIIME2Data/shannon-correlation.qzv

# Simposon
qiime diversity alpha --i-table QIIME2Data/table.qza --p-metric simpson --o-alpha-diversity QIIME2Data/simpson_vector.qza

# Mantel test
qiime diversity mantel --i-dm1 QIIME2Data/core-metrics-results/unweighted_unifrac_distance_matrix.qza --i-dm2 QIIME2Data/core-metrics-results/bray_curtis_distance_matrix.qza --o-visualization QIIME2Data/mantel-test.qzv

# Pylogenetic 
qiime emperor plot --i-pcoa QIIME2Data/core-metrics-results/unweighted_unifrac_pcoa_results.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --o-visualization QIIME2Data/emperor-pcoa.qzv


# Taxonomic Analysis
qiime taxa collapse --i-table QIIME2Data/table.qza --i-taxonomy QIIME2Data/taxonomy.qza --p-level 6 --o-collapsed-table QIIME2Data/collapsed-table-l6.qza
qiime feature-table summarize --i-table QIIME2Data/collapsed-table-l6.qza --o-visualization QIIME2Data/collapsed-table-l6-summary.qzv --m-sample-metadata-file ProcessedData/Qiime2Metadata.tsv

# Differential Abundance Testing
qiime feature-table filter-features --i-table QIIME2Data/table.qza --p-min-samples 2 --o-filtered-table QIIME2Data/filtered-table.qza
qiime composition add-pseudocount --i-table QIIME2Data/filtered-table.qza --o-composition-table QIIME2Data/comp-filtered-table.qza
qiime composition ancom --i-table QIIME2Data/comp-filtered-table.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --m-metadata-column Impact --o-visualization QIIME2Data/ancom-Impact.qzv # Nothing Significant


# Machine Learning
qiime sample-classifier classify-samples --i-table QIIME2Data/table.qza --m-metadata-file ProcessedData/Qiime2Metadata.tsv --m-metadata-column Impact --p-estimator KNeighborsClassifier --o-sample-estimator QIIME2Data/random-forest-sample-estimator.qza --o-feature-importance QIIME2Data/feature-importance.qza --o-predictions QIIME2Data/predictions.qza --p-parameter-tuning --o-model-summary QIIME2Data/model-summary.qzv --o-accuracy-results QIIME2Data/accuracy-results.qzv --o-probabilities QIIME2Data/probabilities.qza --o-heatmap QIIME2Data/heatmap.qzv --o-training-targets QIIME2Data/training-targets.qza --o-test-targets QIIME2Data/test-targets.qza
