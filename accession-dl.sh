#!/bin/bash

# Check if EDirect is installed
if ! command -v esearch &> /dev/null || ! command -v efetch &> /dev/null; then
    echo "NCBI EDirect tools (esearch and efetch) not found. Please install them before running this script."
    exit 1
fi

# Initialize counters
total_accessions=$(grep -c '^[^[:space:]]' accession_list.txt)
echo "Downloading $total_accessions sequences from accession_list.txt"
echo "0" > success_count.tmp
echo "0" > fail_count.tmp

# Create output directory
output_dir="sequence_downloads"
mkdir -p "$output_dir"

# Download each accession using xargs
xargs -a accession_list.txt -I {} sh -c '
    accession="{}"
    output_file="'"$output_dir"'/${accession}.fasta"
    
    # Download sequence from the nucleotide database
    esearch -db nucleotide -query "$accession" | efetch -format fasta > "$output_file"

    # Check if download was successful
    if [ -s "$output_file" ]; then
        echo "Accession $accession downloaded successfully as $output_file"
        success_count=$(<success_count.tmp)
        echo $((success_count + 1)) > success_count.tmp
    else
        echo "Accession $accession failed to download" >> accessionFailedDownload.txt
        rm -f "$output_file"
        fail_count=$(<fail_count.tmp)
        echo $((fail_count + 1)) > fail_count.tmp
    fi
'

# Output the results
success_count=$(<success_count.tmp)
fail_count=$(<fail_count.tmp)
rm success_count.tmp fail_count.tmp

echo "Download complete."
echo "Successfully downloaded: $success_count sequences"
echo "Failed to download: $fail_count sequences"
