# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Style the Dir
styler::style_dir()

# Load Required Packages
suppressMessages({
  library(tidyverse)
  library(ggalluvial)
})

# Define paths for I/O
input_path <- "../RawMetadata"
output_path <- "../ProcessedData"
fq_path <- "../RawSeqData"

# Read the raw metadata
sampleMetadata <- read.table(paste(input_path, "Clean_Metadata.tsv", sep = "/"),
  sep = "\t", header = TRUE,
) %>% as_tibble()

# Create SampleID
sampleMetadata$SampleID <- paste(sampleMetadata$Sample_Number, sampleMetadata$Sample_Name, sep = "-")
sampleMetadata$SampleID <- str_replace_all(sampleMetadata$SampleID, pattern = "_", replacement = "-")

# Load all file-names
fq_files <- data.frame(filename = list.files(fq_path, pattern = ".fastq.gz|R1|R2", full.names = FALSE))
fq_files$test <- str_remove(fq_files$filename, pattern = ".fastq.gz")

# Split the file-names by last _
fq_files <- fq_files %>%
  separate(test, into = c("SampleID", "SampleNum", "i7_i5_idx", "Lane", "R1_R2", "File"), sep = "_", remove = FALSE)

fq_files <- fq_files %>%
  separate(i7_i5_idx, into = c("i7_idx", "i5_idx"), sep = "-", remove = TRUE)

# Update SampleID
fq_files$SampleID <- str_replace_all(fq_files$SampleID, pattern = "-", replacement = "")
fq_files$SampleID <- paste0(fq_files$SampleID, fq_files$SampleNum)

# Update in metadata
sampleMetadata$SampleID <- str_replace_all(sampleMetadata$SampleID, pattern = "-", "")

# Merge the metadata with the file-names
sampleMetadata <- sampleMetadata %>%
  left_join(fq_files, by = c("SampleID" = "SampleID"))

# Drop unused
sampleMetadata <- sampleMetadata %>%
  select(-test)

# Reaaragneg all column
sampleMetadata$Sample_Name <- str_replace_all(sampleMetadata$Sample_Name, pattern = "_", replacement = "")
sampleMetadata <- sampleMetadata %>%
  select(-SampleNum)

# Create New Filename
sampleMetadata$NewFilename <- paste(sampleMetadata$SampleID, "_", sampleMetadata$R1_R2, ".fastq.gz", sep = "")

# # # FileRenaming
# cmd <- paste("mv", paste("..", fq_path, sampleMetadata$filename, sep = "/"), paste("..", fq_path, sampleMetadata$NewFilename, sep = "/"))
# # Write rename
# writeLines(cmd, "01_Data_Preprocessing/RenameFile.sh")

# Write the metadata to a file
write.table(sampleMetadata, paste(output_path, "CleanSampleMetadata.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)

# Create Seq Metadata
seqMetadata <- sampleMetadata %>%
  select(SampleID, i7_idx, i5_idx, NewFilename, Lane, R1_R2, File)

# Group by SampleID
seqMetadata <- seqMetadata %>%
  group_by(SampleID, i7_idx, i5_idx, Lane) %>%
  summarise(
    R1_filename = NewFilename[R1_R2 == "R1"],
    R2_filename = NewFilename[R1_R2 == "R2"],
    .groups = "drop"
  )

# Write the SeqMetadata to a file
write.table(seqMetadata, paste(output_path, "SeqMetadata.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)
