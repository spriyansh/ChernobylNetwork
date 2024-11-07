#!/user/bin/env python3

# Imports
import sys
import pandas as pd

# Check if enough arguments are provided
if len(sys.argv) < 5:
    print("Usage: update_metadata.py <in_tsv> <out_tsv> <r1_col> <r2_col> <path_preceed_str>")
    sys.exit(1)

# Accessing command-line arguments
inFile = sys.argv[1]
outFile = sys.argv[2]
r1_col = sys.argv[3]
r2_col = sys.argv[4]
new_path = sys.argv[5]

# Load the file and print first few columns 
df = pd.read_csv(inFile, sep="\t")

# Remove everything before last / with regex
df["forward-absolute-filepath"] = new_path + "/" +df[r1_col].str.replace(r'.*/', '', regex=True).str.replace(r'_', '_filtered_', regex=True)
df["reverse-absolute-filepath"] = new_path + "/" +df[r2_col].str.replace(r'.*/', '', regex=True).str.replace(r'_', '_filtered_', regex=True)

# Write 
df.to_csv(outFile, sep="\t", index=False)