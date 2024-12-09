# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %
# %
# %
# %
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Style the Dir
# styler::style_dir()

# Load Required Packages
suppressMessages({
  library(tidyverse)
  library(ggalluvial)
})

# subSample_percentage
subSample_percentage <- 1

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
sub_path <- "/home/spriyansh29/Projects/Chernobyl_Network_Nextflow/RawSeqDataSub/"

# Add absolute paths to the fastq files
qiime2Metadata[["r1_absolute"]] <- paste0(sub_path, qiime2Metadata$ForwardFastqFile)
qiime2Metadata[["r2_absolute"]] <- paste0(sub_path, qiime2Metadata$ReverseFastqFile)

# Subset
qiime2Metadata_no_impact <- qiime2Metadata[(qiime2Metadata$Pine_Plantation == "No" & qiime2Metadata$Impact == "No"), ][c(1:9), ]
qiime2Metadata_low_impact <- qiime2Metadata[(qiime2Metadata$Pine_Plantation == "No" & qiime2Metadata$Impact == "Low"), ][c(1:20), ]
qiime2Metadata_high_impact <- qiime2Metadata[(qiime2Metadata$Pine_Plantation == "No" & qiime2Metadata$Impact == "High"), ][c(1:3), ]
qiime2Metadata_high_impact_pine <- qiime2Metadata[(qiime2Metadata$Pine_Plantation == "Yes" & qiime2Metadata$Impact == "High"), ][c(1:24), ]

# Combine
qiime2Metadata_subset <- rbind(qiime2Metadata_no_impact, qiime2Metadata_low_impact, qiime2Metadata_high_impact, qiime2Metadata_high_impact_pine)

View(qiime2Metadata_subset)

# Write Qiime2 Data
write.table(qiime2Metadata_subset,
  file = "Qiime2Metadata.tsv",
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)

# Write Sub-Sample Command
# reformat.sh in1=1243_R1.fastq.gz in2=1243_R2.fastq.gz out1=sub1243_R1.fastq.gz out2=sub1243_R2.fastq.gz samplerate=0.4
cmd <- c(paste0("rm -rf ", sub_path), paste0("mkdir -p ", sub_path), paste0(
  "reformat.sh",
  " in1=", paste0(abs_path, qiime2Metadata_subset$ForwardFastqFile),
  " in2=", paste0(abs_path, qiime2Metadata_subset$ReverseFastqFile),
  " out1=", paste0(sub_path, qiime2Metadata_subset$ForwardFastqFile),
  " out2=", paste0(sub_path, qiime2Metadata_subset$ReverseFastqFile),
  " samplerate=", subSample_percentage
))

# Write the command
write(cmd, file = "01_Data_Preprocessing/Subsample.sh")
