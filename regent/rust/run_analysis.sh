#!/bin/bash

# Check if the argument is provided
if [ -z "$1" ]; then
  echo "Error: No argument provided."
  echo "Usage: $0 <argument>"
  exit 1
fi

# The argument to be passed to the Python scripts
arg="$1"

# Invoke the Python scripts sequentially
python3 combine_tsv.py "$arg"
python3 graph.py "$arg"
python3 bubble.py "$arg"
