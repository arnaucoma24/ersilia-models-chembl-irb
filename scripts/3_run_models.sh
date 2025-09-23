#!/usr/bin/env bash

# Change CWD
PATH_TO_ERSILIA="/aloy/home/acomajuncosa/Ersilia"
PATH_TO_MODELS="$PATH_TO_ERSILIA/data/ersilia_models.txt"
PATH_TO_EMH="$PATH_TO_ERSILIA/ErsiliaModelHub"

# Read Ersilia models one by one
while IFS= read -r line; do
    echo "Line: $line"
done < "$PATH_TO_MODELS"