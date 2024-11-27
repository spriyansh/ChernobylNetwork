# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %
# %
# %
# %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Style the Dir
styler::style_dir()

# Load Required Packages
suppressMessages({
  library(tidyverse)
  library(ggalluvial)
})

# Define paths for I/O
input_path <- "../ProcessedData"
output_path <- "../ProcessedData"

# Read the raw metadata
sampleMetadata <- read.table(paste(input_path, "CleanSampleMetadata.tsv", sep = "/"),
  sep = "\t", header = TRUE,
) %>% as_tibble()

# Read Metadata
seqMetadata <- read.table(paste(input_path, "SeqMetadata.tsv", sep = "/"),
  sep = "\t", header = TRUE,
) %>% as_tibble()


# Rename columns to match QIIME 2's metadata requirements
qiime2Metadata <- seqMetadata %>%
  rename(
    "sampleid" = SampleID,
    ForwardFastqFile = R1_filename,
    ReverseFastqFile = R2_filename,
    BarcodeSequence = i7_idx,
    LinkerPrimerSequence = i5_idx
  )
qiime2Metadata$Description <- paste0("Sample", qiime2Metadata$sampleid)

# Rename
sampleMetadata <- sampleMetadata %>%
  rename("sampleid" = SampleID)

# Extract Sample Characterstics
sampleCharacters <- sampleMetadata[, c(
  "sampleid", "SQ_Burn_Score", "Moisture", "pH", "Loss_on_Ignition",
  "Envrn_Dose_Rate", "Strontium_90_BqG", "Cesium_137_BqG", "Americium_241_BqG",
  "Plutonium_BqG", "Grass_Dry_Weight_G", "Veg_Other_Dry_Weight_G", "Total_Veg_Dry_Weight_G",
  "Bites_Sept17", "NH4_MgKg_DwSoil", "NO3_MgKg_DwSoil", "Bacterial_Dose_Rate", "Source",
  "Latitude", "Longitude", "Pine_Plantation", "Impact", "Sample_Type"
)]

# Merge the metadata with the file-names
qiime2Metadata <- qiime2Metadata %>%
  left_join(sampleCharacters, by = c("sampleid" = "sampleid")) %>%
  distinct()

# Add absoulte paths
abs_path <- "/home/spriyansh29/Projects/Chernobyl_Network_Nextflow/RawSeqData/"

# Add absolute paths to the fastq files
qiime2Metadata[["r1_absolute"]] <- paste0(abs_path, qiime2Metadata$ForwardFastqFile)
qiime2Metadata[["r2_absolute"]] <- paste0(abs_path, qiime2Metadata$ReverseFastqFile)

# Remove certain samples
qiime2Metadata <- qiime2Metadata %>%
  filter(!Impact == "Low")

# Remove Non-Pine Samples with high impact
qiime2Metadata <- qiime2Metadata[!(qiime2Metadata$Pine_Plantation == "No" & qiime2Metadata$Impact == "High"), ]

# Separate
High <- qiime2Metadata[qiime2Metadata$Impact == "High", ][c(1:8), ]
Control <- qiime2Metadata[qiime2Metadata$Impact == "No", ][c(1:8), ]

# Check plutonium
High <- High[High$Plutonium_BqG > 5, ]

# Rbind
qiime2Metadata <- rbind(High, Control)

View(qiime2Metadata)

# Write Qiime2 Data
write.table(qiime2Metadata,
  file = paste(output_path, "Qiime2Metadata.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)

# Write test
qiime2Metadata <- qiime2Metadata[c(1:4), ]

# Replace the abosulte paths
qiime2Metadata$sampleid <- paste0("sub", qiime2Metadata$sampleid)
qiime2Metadata$ForwardFastqFile <- paste0("sub", qiime2Metadata$ForwardFastqFile)
qiime2Metadata$ReverseFastqFile <- paste0("sub", qiime2Metadata$ReverseFastqFile)
qiime2Metadata[["r1_absolute"]] <- paste0(abs_path, qiime2Metadata$ForwardFastqFile)
qiime2Metadata[["r2_absolute"]] <- paste0(abs_path, qiime2Metadata$ReverseFastqFile)

write.table(qiime2Metadata,
  file = paste(output_path, "Qiime2Metadata_Test.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)
