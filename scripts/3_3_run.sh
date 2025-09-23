#!/bin/bash
set -euo pipefail

# Load variables
model="$1"
PATH_TO_ERSILIA="$2"
PATH_TO_SMILES="$3"
PATH_TO_RESULTS="$4"
task_id="$5"

# Define home to store sessions info
# export HOME="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/tmp/$model/.eos_$task_id"
export HOME="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/tmp/$model"


# # Initialize conda
# eval "$(conda shell.bash hook)"
# conda activate "$PATH_TO_ERSILIA"/envs/ersilia


echo " ------------ "
conda run -p "$PATH_TO_ERSILIA"/envs/ersilia ersilia catalog

files=("$PATH_TO_SMILES"/*.csv)
smiles_file="${files[$task_id]}"

# ersilia serve "$model"
# ersilia run -i "$smiles_file" -o ."$PATH_TO_RESULTS/results_$task_id.csv"

sleep 5
