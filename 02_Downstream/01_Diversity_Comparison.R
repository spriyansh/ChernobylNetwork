# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Load Required Packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(phyloseq)
  library(tidyverse)
  library(vegan)
})

# Load Metadata
metadata <- read.table("Qiime2Metadata.tsv", header = TRUE, sep = "\t", row.names = 1)
metadata_phy <- sample_data(metadata)

# Define paths for I/O (Relative to paths)
parent <- "../Nextflow_Output_AWS/Qiime2Data/Qiime2_Exports"

# Outpath
outpath <- "../Nextflow_Output_Downstream"
dir.create(outpath, showWarnings = FALSE)

# Taxanomy
otu_tax_path <- paste(parent, "OTU-Taxanomy/taxonomy.tsv", sep = "/")
asv_tax_path <- paste(parent, "ASV-Taxanomy/taxonomy.tsv", sep = "/")

# Feature
otu_abud_path <- paste(parent, "OTU-FeatureTable/feature-table.tsv", sep = "/")
asv_abud_path <- paste(parent, "ASV-FeatureTable/feature-table.tsv", sep = "/")

# Create List
tax_abud_s3 <- list(
  "OTU" = list(
    taxanomy_file_path = otu_tax_path,
    abundance_file_path = otu_abud_path
  ),
  "ASV" = list(
    taxanomy_file_path = asv_tax_path,
    abundance_file_path = asv_abud_path
  )
)

# Load Data and perform basic conversions
load_convert <- function(tax_abud_list) {
  # Load the taxanomy file
  tax <- read.table(tax_abud_list$taxanomy_file_path, sep = "\t", header = TRUE, row.names = 1)

  # Split the Taxanomy
  tax <- tax %>%
    separate(Taxon,
      into = c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species"),
      sep = "; ", fill = "right"
    )
  tax <- as.matrix(tax)

  # Load Counts
  counts <- as.matrix(read.table(tax_abud_list$abundance_file_path, sep = "\t", header = FALSE, row.names = 1))

  # Convert to the phylo-Objects
  counts_phy <- otu_table(counts, taxa_are_rows = TRUE)
  tax_phy <- tax_table(tax)

  # Update Samples Names
  sample_names(counts_phy) <- sample_names(metadata_phy)

  # Create PhyloObject
  physeqObject <- phyloseq(counts_phy, tax_phy, metadata_phy)

  # Add to the list
  tax_abud_list$physeq <- physeqObject
  tax_abud_list$counts <- counts
  tax_abud_list$tax <- tax

  # Return the list
  return(tax_abud_list)
}

# lapply
tax_abud_s3 <- lapply(tax_abud_s3, FUN = load_convert)

## Test
# tax_abud_list <- tax_abud_s3$OTU

# Compute Diversity Indexes
compute_diversity_indexes <- function(tax_abud_list) {
  # Alpha Diversity
  alpha_div <- estimate_richness(tax_abud_list$physeq, measures = c("Observed", "Shannon", "Simpson", "Chao1"))

  # Convert to long form for plotting
  alpha_div <- alpha_div %>%
    rownames_to_column(var = "Sample") %>%
    pivot_longer(
      cols = c("Observed", "Shannon", "Simpson", "Chao1"),
      names_to = "Diversity_Index",
      values_to = "Value"
    )
  # Apply log transformation
  alpha_div$LogValue <- log10(alpha_div$Value + 1)

  # Plot and Save
  alpha_indexes_plt <- ggplot(alpha_div, aes(x = Diversity_Index, y = LogValue, fill = Diversity_Index)) +
    geom_boxplot() +
    facet_wrap(~Diversity_Index, scales = "free") +
    theme_minimal() +
    labs(
      title = "Alpha Diversity Indexes",
      x = "Diversity Index",
      y = "Log10(x+1)"
    ) +
    scale_fill_brewer(palette = "Dark2") +
    theme(legend.position = "none")

  ## Add to list
  tax_abud_list$alpha_div <- alpha_div
  tax_abud_list$alpha_indexes_plt <- alpha_indexes_plt

  ## Calculate Beta Diversity using the Impacted Samples
  ordination <- ordinate(tax_abud_list$physeq, method = "PCoA", distance = "bray")
  ord_df <- ordination$vectors[, c(1:2)] %>%
    as.data.frame() %>%
    rownames_to_column(var = "sample_id") %>%
    as_tibble() %>%
    rename(c1 = Axis.1, c2 = Axis.2)
  metadata_subset <- metadata %>%
    select(c("Impact", "Pine_Plantation")) %>%
    rownames_to_column(var = "sample_id")
  ord_df <- ord_df %>% inner_join(metadata_subset, by = "sample_id")

  ## Plot
  beta_indexes_plt <- ggplot(data = ord_df, mapping = aes(x = c1, y = c2, shape = Impact, color = Pine_Plantation)) +
    geom_point(size = 3.5, alpha = 0.8) +
    theme_minimal() +
    labs(title = "Beta Diversity", shape = "Impact", color = "Is Pine Plantation") +
    scale_color_brewer(palette = "Dark2") +
    theme(legend.position = "bottom")

  ## Add to list
  tax_abud_list$beta_div <- ordination
  tax_abud_list$beta_indexes_plt <- beta_indexes_plt

  # Estimating Richness
  richness_indexes_plt <- plot_richness(tax_abud_list$physeq, x = "Impact", color = "Pine_Plantation", measures = c("Observed", "Shannon", "Simpson", "Chao1")) +
    theme_minimal() + theme(legend.position = "bottom") + labs(title = "Richness Indexes", color = "Is Pine Plantation?") +
    scale_color_brewer(palette = "Dark2")

  # Add to list
  tax_abud_list$richness_indexes_plt <- richness_indexes_plt
  #
  # # Compute rarefaction
  # rarefaction <- rarecurve(t(tax_abud_list$counts), step = 20, col = "seagreen", label = FALSE)
  #
  # # Save the plot
  # tax_abud_list$rarefaction <- rarefaction

  return(tax_abud_list)
}

# Compute
div_results <- lapply(tax_abud_s3, FUN = compute_diversity_indexes)

# Export Results RDS Object
dir.create(paste(outpath, "RDS_Objects", sep = "/"), showWarnings = FALSE)
saveRDS(div_results, file = paste(paste(outpath, "RDS_Objects", sep = "/"), "Diversity_Comparison.RDS", sep = "/"))
