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

# Read the qiime2 metadata
qiime2Metadata <- read.table(paste(output_path, "Qiime2Metadata.tsv", sep = "/"),
  sep = "\t", header = TRUE,
) %>% as_tibble()

# Select Relevant Columns
mothurStabData <- qiime2Metadata %>%
  select(sampleid, r1_absolute, r2_absolute)

# Transfer
mothurStabData_test <- mothurStabData

# Remove pre-fix
mothurStabData_test$r1_absolute <- vapply(str_split(mothurStabData_test$r1_absolute, pattern = "/"), FUN = function(x) {
  x[7]
}, FUN.VALUE = "character")
mothurStabData_test$r2_absolute <- vapply(str_split(mothurStabData_test$r2_absolute, pattern = "/"), FUN = function(x) {
  x[7]
}, FUN.VALUE = "character")

# Write test
write.table(mothurStabData[c(1:4), ],
  file = "/home/spriyansh29/Projects/Chernobyl_Network_Nextflow/MOTHUR_TESTING/MothurStabilityData_Test.tsv",
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = FALSE
)
# Write main files
write.table(mothurStabData,
  file = paste(output_path, "MothurStabilityData.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = FALSE
)
