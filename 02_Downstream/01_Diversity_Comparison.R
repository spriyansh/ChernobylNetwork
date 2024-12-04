# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Year: 2021 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Style the Dir
styler::style_dir()

# Load Required Packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(phyloseq)
  library(tidyverse)
  library(vegan)
})

# Load Metadata
metadata <- read.table("../ProcessedData/Qiime2Metadata.tsv", header = TRUE, sep = "\t", row.names = 1)
metadata_phy <- sample_data(metadata)

# Define paths for I/O (Relative to paths)
parent <- "../Nextflow_Output/Qiime2Data/Qiime2_Exports"

# Outpath
outpath <- "../Nextflow_Output/Downstream"
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

# Compute Alpha Diversity Indexs
alpha_div <- estimate_richness(tax_abud_s3$OTU$physeq, measures = c("Observed", "Shannon", "Simpson", "Chao1"))
print(alpha_div)

alpha_div_long <- alpha_div %>%
  rownames_to_column(var = "Sample") %>%
  pivot_longer(
    cols = c("Observed", "Shannon", "Simpson", "Chao1"),
    names_to = "Diversity_Index",
    values_to = "Value"
  )

# Log-transform (optional) to reduce scale differences
alpha_div_long$Value <- log10(alpha_div_long$Value + 1)


ggplot(alpha_div_long, aes(x = Diversity_Index, y = Value, fill = Diversity_Index)) +
  geom_boxplot() +
  facet_wrap(~Diversity_Index, scales = "free") + # Separate scales for each index
  theme_minimal() +
  labs(
    title = "Alpha Diversity Indexes (Facet View)",
    x = "Diversity Index",
    y = "Log-transformed Value"
  ) +
  scale_fill_brewer(palette = "Set3")


# Ordination
ordination <- ordinate(tax_abud_s3$OTU$physeq, method = "PCoA", distance = "bray")
plot_ordination(tax_abud_s3$OTU$physeq, ordination, color = "Impact") + geom_point(size = 3)


plot_richness(tax_abud_s3$OTU$physeq, x = "Impact", measures = c("Observed", "Shannon", "Simpson", "Chao1")) +
  theme_minimal()

plot_bar(tax_abud_s3$OTU$physeq, fill = "Phylum") + theme_minimal()

rarecurve(t(tax_abud_s3$OTU$counts), step = 20, col = "blue", label = FALSE)
