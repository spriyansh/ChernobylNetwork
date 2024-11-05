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
  library(dada2)
})

# Define paths for I/O
input_path <- "../ProcessedData"
output_path <- "../ProcessedData"

# Read Qiime2 Metadata
q2Metadata <- read.table(paste(output_path, "Qiime2Metadata.tsv", sep = "/"),
  sep = "\t", header = TRUE
)

# Create Names
fnFs <- q2Metadata$forward.absolute.filepath
fnRs <- q2Metadata$reverse.absolute.filepath
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)

p <- plotQualityProfile(fnFs[1]) + ggtitle("hakuna")
