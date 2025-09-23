#!/usr/bin/env bash
set -euo pipefail

# ---- Paths (edit if your layout changes) ----
PATH_TO_ERSILIA="/aloy/home/acomajuncosa/Ersilia"
PATH_TO_MODELS="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/ersilia_models.txt"
PATH_TO_EMH="$PATH_TO_ERSILIA/ErsiliaModelHub"
PATH_TO_ENV="$PATH_TO_ERSILIA/envs/ersilia"
PATH_TO_SMILES="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/splits"
PATH_TO_RESULTS="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/results"

# Change WD
mkdir -p "$PATH_TO_ERSILIA"
cd "$PATH_TO_ERSILIA"

# ---- Create/ensure env (Python 3.10) ----
if [ ! -d "$PATH_TO_ENV" ]; then
  conda create -p "$PATH_TO_ENV" -y python=3.10
fi

# ---- Clone or re-clone ersilia repo ----
if [ -d "$PATH_TO_ERSILIA/ersilia" ]; then
  echo "[ersilia] removing existing repo..."
  rm -rf "$PATH_TO_ERSILIA/ersilia"
fi
echo "[ersilia] cloning fresh..."
git clone --depth=1 https://github.com/ersilia-os/ersilia.git "$PATH_TO_ERSILIA/ersilia"


# ---- Install ersilia in the *conda env* ----
echo "[ersilia] installing in env..."
conda run -p "$PATH_TO_ENV" python -m pip install -U pip
conda run -p "$PATH_TO_ENV" python -m pip install -e "$PATH_TO_ERSILIA/ersilia"

# ---- Clone models listed in file ----
mkdir -p "$PATH_TO_EMH"
cd "$PATH_TO_EMH"

while IFS= read -r model || [[ -n "${model:-}" ]]; do
  # Skip empty lines or lines starting with '#' (comments in the file)
  [[ -z "${model// }" || "$model" =~ ^# ]] && continue
  echo "[model] $model"

  # Define model path and url
  repo_dir="$PATH_TO_EMH/$model"
  repo_url="https://github.com/ersilia-os/${model}"

  # Remove directory if existing
  if [ -d "$repo_dir" ]; then
    echo "  -> removing existing repo..."
    rm -rf "$repo_dir"
  fi

  # Cloning directory
  echo "  -> cloning fresh..."
  git clone --depth=1 "$repo_url" "$repo_dir"
  
  # Create output directory
  mkdir -p "$PATH_TO_RESULTS/${model}"

  # Create logs directory
  mkdir -p "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/logs"

  # Send job to the cluster
  N=$(ls "$PATH_TO_SMILES"/*.csv | wc -l)
  ssh acomajuncosa@irblogin02 --job-name='${model}' --array=0-$((n-1))\
  "sbatch '$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts/3_2_job_submission.sh' '$PATH_TO_SMILES' '$PATH_TO_RESULTS/${model}'"


done < "$PATH_TO_MODELS"