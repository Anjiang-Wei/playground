#!/bin/bash

# Check if the base directory argument is provided
if [ -z "$1" ]; then
  echo "Error: No base directory provided."
  echo "Usage: $0 <base_directory>"
  exit 1
fi

# Base directory containing the directories to iterate
base_dir="$1"

# Iterate over each top-level directory in base_dir
for top_level_dir in "$base_dir"/*; do
  # Iterate over each subdirectory in the top-level directory
  for sub_dir in "$top_level_dir"/*; do
    # Skip the 'prof' directory if it already exists
    if [ "$(basename "$sub_dir")" == "prof" ]; then
      continue
    fi
    
    # Define the output directory
    output_dir="$sub_dir/prof"
    
    # Run the legion_prof command in the background if the 'prof' directory does not already exist
    if [ ! -d "$output_dir" ]; then
      legion_prof "$sub_dir"/* -o "$output_dir" &
    else
      echo "Skipping $sub_dir, prof directory already exists."
    fi
  done
done

# Wait for all background jobs to complete
wait
