library(DESeq2)
library(phyloseq)
library(tidyverse)









physeq <- phyloseq(otu_matrix, metadata_phy)

dds <- phyloseq_to_deseq2(physeq, ~Impact)

dds <- DESeq(dds)
res <- results(dds)

res <- res[order(res$padj, na.last = NA), ]
head(res)

alpha <- 0.05 
log2fc_threshold <- 0.5 
sig_taxa <- res %>%
  as.data.frame() %>%
  filter(padj < alpha & abs(log2FoldChange) > log2fc_threshold)

print(sig_taxa)


library(ggplot2)

res_df <- as.data.frame(res)
ggplot(res_df, aes(x = log2FoldChange, y = -log10(padj))) +
  geom_point(aes(color = padj < 0.05)) +
  theme_minimal() +
  labs(title = "Volcano Plot", x = "Log2 Fold Change", y = "-Log10 Adjusted p-value") +
  scale_color_manual(values = c("gray", "red")) # Red points = significant



library(pheatmap)


sig_otu_counts <- otu_table(physeq)[rownames(sig_taxa), ]
pheatmap(as.matrix(sig_otu_counts), cluster_rows = TRUE, cluster_cols = TRUE, scale = "row")
