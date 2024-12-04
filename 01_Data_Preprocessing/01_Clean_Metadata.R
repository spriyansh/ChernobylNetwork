# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# % Author: Priyansh Srivastava %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Year: 2021 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Style the Dir
styler::style_dir()

# Load Required Packages
suppressMessages({
  library(tidyverse)
  library(ggalluvial)
})

# Define paths for I/O
input_path <- "../RawMetadata"
output_path <- "../RawMetadata"

# Read the raw metadata
rawMetadata <- read.table(paste(input_path, "md_for_phyloseq.csv", sep = "/"),
  sep = ",", header = TRUE, skip = 6
) %>% as_tibble()

# Rename the Columns
colnames(rawMetadata) <- c(
  "Sample_Number", "Sample_Name", "SQ_Burn_Score", "Moisture", "pH", "Loss_on_Ignition",
  "Envrn_Dose_Rate", "Strontium_90_BqG", "Cesium_137_BqG", "Americium_241_BqG", "Plutonium_BqG",
  "Grass_Dry_Weight_G", "Veg_Other_Dry_Weight_G", "Total_Veg_Dry_Weight_G", "NABclass", "Bites_Sept17",
  "NH4_MgKg_DwSoil", "NO3_MgKg_DwSoil",
  "Bacterial_Dose_Rate", "Source", "Pine"
)

# Remove row-1
rawMetadata <- rawMetadata[-1, ]

# Load Geo Locations
geoLocations <- read.table(paste(input_path, "geo_coordinates.tsv", sep = "/"),
  sep = "\t", header = TRUE
) %>% as_tibble()

# Rename Columns
colnames(geoLocations) <- c("Sample_Name", "Latitude", "Longitude")

# Left join the metadata with geo locations
rawMetadata <- left_join(rawMetadata, geoLocations, by = "Sample_Name")

# Fix the string columns
rawMetadata$Pine_Plantation <- ifelse(rawMetadata$Pine == "Never", "No", NA)
rawMetadata$Pine_Plantation <- ifelse(rawMetadata$Pine == "Control (not pine)", "No", rawMetadata$Pine_Plantation)
rawMetadata$Pine_Plantation <- ifelse(is.na(rawMetadata$Pine_Plantation), "Yes", rawMetadata$Pine_Plantation)

# Fix Impact
rawMetadata$Impact <- ifelse(rawMetadata$Pine == "Never", "Low", NA)
rawMetadata$Impact <- ifelse(rawMetadata$NABclass == "Buriakivka", "No", rawMetadata$Impact)
rawMetadata$Impact <- ifelse(rawMetadata$NABclass == "Red Forest", "High", rawMetadata$Impact)

# Fix Pine_Forest Column
rawMetadata$Sample_Type <- ifelse(rawMetadata$Pine == "Control (not pine)", "Control", NA)
rawMetadata$Sample_Type <- ifelse(is.na(rawMetadata$Sample_Type), "Exposed", rawMetadata$Sample_Type)

# Fixing Source
rawMetadata$Source <- rawMetadata$NABclass
rawMetadata$Source <- ifelse(rawMetadata$Source == "Red Forest good", "Red Forest", rawMetadata$Source)

## Remove unused columns
rawMetadata <- rawMetadata %>%
  select(-c("Pine", "NABclass"))

## Create Visuals
View(rawMetadata)

# Count occurrences for each combination of categories
df_summary <- rawMetadata %>%
  dplyr::count(Pine_Plantation, Impact, Source, Sample_Type) %>%
  mutate(Proportion = n / sum(n))

# Plot proportion
p <- ggplot(
  df_summary,
  aes(
    axis1 = Pine_Plantation, axis2 = Impact, axis3 = Source, axis4 = Sample_Type,
    y = Proportion
  )
) +
  geom_alluvium(aes(fill = Impact), width = 0.2) +
  geom_stratum(width = 0.2) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum))) +
  scale_x_discrete(limits = c("Pine_Plantation", "Impact", "Source", "Sample_Type"), expand = c(0.15, 0.05)) +
  labs(title = "Proportion of Samples", x = "Categories", y = "Proportion") +
  scale_fill_brewer(palette = "Set1") +
  theme_minimal()

# Save the Plot and the metadata
ggsave("../ProcessedData/img/Proportion_of_Samples.png", p,
  width = 8, height = 8,
  dpi = 300, create.dir = TRUE, bg = "white"
)

# Fix data types of the columns
rawMetadata$Sample_Number <- as.integer(rawMetadata$Sample_Number)
rawMetadata$Sample_Name <- as.character(rawMetadata$Sample_Name)
rawMetadata$SQ_Burn_Score <- as.integer(rawMetadata$SQ_Burn_Score)
rawMetadata$Moisture <- as.numeric(rawMetadata$Moisture)
rawMetadata$pH <- as.numeric(rawMetadata$pH)
rawMetadata$Loss_on_Ignition <- as.numeric(rawMetadata$Loss_on_Ignition)
rawMetadata$Envrn_Dose_Rate <- as.numeric(rawMetadata$Envrn_Dose_Rate)
rawMetadata$Strontium_90_BqG <- as.numeric(rawMetadata$Strontium_90_BqG)
rawMetadata$Cesium_137_BqG <- as.numeric(rawMetadata$Cesium_137_BqG)
rawMetadata$Americium_241_BqG <- as.numeric(rawMetadata$Americium_241_BqG)
rawMetadata$Plutonium_BqG <- as.numeric(rawMetadata$Plutonium_BqG)
rawMetadata$Grass_Dry_Weight_G <- as.numeric(rawMetadata$Grass_Dry_Weight_G)
rawMetadata$Veg_Other_Dry_Weight_G <- as.numeric(rawMetadata$Veg_Other_Dry_Weight_G)
rawMetadata$Total_Veg_Dry_Weight_G <- as.numeric(rawMetadata$Total_Veg_Dry_Weight_G)
rawMetadata$Bites_Sept17 <- as.integer(rawMetadata$Bites_Sept17)
rawMetadata$NH4_MgKg_DwSoil <- as.numeric(rawMetadata$NH4_MgKg_DwSoil)
rawMetadata$NO3_MgKg_DwSoil <- as.numeric(rawMetadata$NO3_MgKg_DwSoil)
rawMetadata$Bacterial_Dose_Rate <- as.numeric(rawMetadata$Bacterial_Dose_Rate)
rawMetadata$Latitude <- as.numeric(rawMetadata$Latitude)
rawMetadata$Longitude <- as.numeric(rawMetadata$Longitude)
rawMetadata$Pine_Plantation <- as.factor(rawMetadata$Pine_Plantation)
rawMetadata$Impact <- as.factor(rawMetadata$Impact)
rawMetadata$Source <- as.factor(rawMetadata$Source)
rawMetadata$Sample_Type <- as.factor(rawMetadata$Sample_Type)

# Order data by sample Number
rawMetadata <- rawMetadata %>%
  arrange(Sample_Number)

# Write the metadata to a file
write.table(rawMetadata, paste(output_path, "Clean_Metadata.tsv", sep = "/"),
  sep = "\t", row.names = FALSE, quote = FALSE,
  col.names = TRUE
)
