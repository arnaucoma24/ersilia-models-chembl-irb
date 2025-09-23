#!/usr/bin/env bash

# Define some paths
PATH_TO_ERSILIA="/home/arnau/myfolder/myfile.txt"
PATH_TO_EMH="/home/arnau/myfolder/myfile.txt"

# ii) Read a txt file line by line
while IFS= read -r line; do
    echo "Line: $line"
done < "$MY_PATH"