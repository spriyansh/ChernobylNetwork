# Load necessary libraries
library(SpiecEasi)
library(Matrix)
library(igraph)

# Step 1: Load and Filter Data
# Replace 'filtered-cooccurrence-table.tsv' with your exported feature table file path
feature_table <- read.table("~/Projects/Chernobyl_Network_Nextflow/QIIME2Data/ExportedData/filtered-cooccurrence-table/filtered-cooccurrence-table.tsv",
                            header = TRUE, row.names = 1, sep = "\t"
)

# Step 2: Convert Data to Matrix
# Remove the first column if it's a sample identifier (adjust as necessary)
feature_matrix <- as.matrix(feature_table)

# Step 3: Run SpiecEasi to Construct the Network
# Using Meinshausen-Bühlmann (mb) method for network inference
spiec <- spiec.easi(feature_matrix, method = "mb", nlambda = 50, lambda.min.ratio = 1e-2)

# Step 4: Extract Adjacency Matrix
# Extract the adjacency matrix from the SpiecEasi object
adj_matrix <- as.matrix(symBeta(getOptBeta(spiec), mode = "maxabs"))

# Step 5: Create an igraph Object
# Convert the adjacency matrix to an igraph object
network <- graph_from_adjacency_matrix(adj_matrix, mode = "undirected", diag = FALSE, weighted = TRUE)

# Step 6: Optional - Filter Edges by Weight Threshold
# Set a threshold to remove weaker edges (e.g., edges with weight < 0.3)
threshold <- 0.3
network <- delete_edges(network, E(network)[abs(E(network)$weight) < threshold])

# Step 7: Plot the Network
plot(
  network,
  vertex.size = 5, # Adjust node size as needed
  vertex.label = NA, # Remove labels for a cleaner view
  edge.width = E(network)$weight * 5, # Scale edge width by weight
  main = "Filtered Co-occurrence Network"
)

# Step 8: Additional Analysis (Optional)
# Calculate centrality metrics if needed (betweenness, degree, etc.)
centrality <- data.frame(
  degree = degree(network),
  betweenness = betweenness(network),
  closeness = closeness(network)
)

# Print top nodes by centrality measures
print(head(centrality[order(-centrality$degree), ], 10)) # Top 10 nodes by degree

# End of Script
