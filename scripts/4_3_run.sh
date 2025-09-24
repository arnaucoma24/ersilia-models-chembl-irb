#!/bin/bash
set -euo pipefail

# Load variables
model="$1"
PATH_TO_ERSILIA="$2"
PATH_TO_SMILES="$3"
PATH_TO_RESULTS="$4"
task_id="$5"

# Initialize conda
eval "$(conda shell.bash hook)"
conda activate "$PATH_TO_ERSILIA/envs/ersilia"

# Get SMILES file
echo "------------"
files=("$PATH_TO_SMILES"/*.csv)
smiles_file="${files[$task_id]}"
echo "Running on file: $smiles_file"

# Split SMILES file in groups of 100 compounds
cd "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts"
python "./4_4_split.py" \
  --input_file "$smiles_file" \
  --output_dir "$PATH_TO_RESULTS" \
  --model "$model" \
  --task_id "$task_id"

# Run Ersilia model
cd "$PATH_TO_ERSILIA/ErsiliaModelHub/$model/model/framework"
conda activate "$PATH_TO_ERSILIA/envs/$model"
task_id_z=$(printf "%03d" "$task_id")

for split_file in "$PATH_TO_RESULTS/$model"_"$task_id_z"_tmp/split_*.csv; do
  [ -e "$split_file" ] || break   # safety: exit if no split files exist
  x="${split_file##*/}"           # take just the filename, e.g. split_7.csv
  x="${x#split_}"                 # remove "split_", now it's 7.csv
  x="${x%.csv}"                   # remove ".csv", now it's just 7

  # run the model on this split file
  bash run.sh . "$split_file" "$PATH_TO_RESULTS/${model}_${task_id_z}_tmp/results_${x}.csv"
done

# Join results
conda activate "$PATH_TO_ERSILIA/envs/ersilia"
cd "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts"
python "./4_5_join.py" \
  --input_file "$smiles_file" \
  --output_dir "$PATH_TO_RESULTS" \
  --model "$model" \
  --task_id "$task_id" \
  --path_to_ersilia "$PATH_TO_ERSILIA"
