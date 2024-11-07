#!/bin/bash

# CLI arguments
input_file="$1"
output_file="$2"
sample_column="$3"
new_column="$4"
add_string="$5"

# Run the awk command with arguments
awk -F'\t' -v OFS='\t' -v sample_column="$sample_column" -v new_column="$new_column" -v add_string="$add_string" '
NR==1 {
    # Find the index of the column with name given by sample_column
    for (i=1; i<=NF; i++) {
        if ($i == sample_column) col_index = i
    }
    # Print header row with new column name
    print $0, new_column
    next
}
{
    # Print each row with the specified column value concatenated with add_string
    print $0, add_string $col_index
}' "$input_file" > "$output_file"
