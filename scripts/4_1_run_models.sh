#!/usr/bin/env bash
set -euo pipefail

# ---- Paths (edit if your layout changes) ----
PATH_TO_ERSILIA="/aloy/home/acomajuncosa/Ersilia"
PATH_TO_MODELS="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/ersilia_models.txt"  # ersilia models listed
PATH_TO_EMH="$PATH_TO_ERSILIA/ErsiliaModelHub"  # ersilia models cloned
PATH_TO_ENV="$PATH_TO_ERSILIA/envs/ersilia"  # ersilia package
PATH_TO_SMILES="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/splits"  # splits of 10k compounds
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
echo "[ersilia] installing in conda env..."
conda run -p "$PATH_TO_ENV" python -m pip install -U pip
conda run -p "$PATH_TO_ENV" python -m pip install -e "$PATH_TO_ERSILIA/ersilia"
echo "[ersilia] printing ersilia help..."
conda run -p "$PATH_TO_ENV" ersilia --help
conda run -p "$PATH_TO_ENV" ersilia catalog

# ---- Clone models listed in file ----
mkdir -p "$PATH_TO_EMH"
cd "$PATH_TO_EMH"

while IFS= read -r model || [[ -n "${model:-}" ]]; do
  # Skip empty lines or lines starting with '#' (comments in the file)
  [[ -z "${model// }" || "$model" =~ ^# ]] && continue
  echo "[model] $model"

  # Redefine HOME dir
  export HOME="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/tmp/$model"

  # Define model path and url
  repo_dir="$PATH_TO_EMH/$model"
  repo_url="https://github.com/ersilia-os/${model}"

  # Remove directory if existing
  if [ -d "$repo_dir" ]; then
    echo "  --> removing existing repository..."
    rm -rf "$repo_dir"
  fi

  # Cloning directory
  echo "  --> cloning fresh..."
  git clone --depth=1 "$repo_url" "$repo_dir"

  # Fetching model
  echo "  --> fetching from_dir..."
  conda run -p "$PATH_TO_ENV" ersilia -v fetch "$model" --from_dir "$repo_dir"

  # Create output directory
  mkdir -p "$PATH_TO_RESULTS/${model}"

  # Create logs directory
  mkdir -p "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/logs/${model}"

  conda run -p "$PATH_TO_ENV" ersilia catalog

  # # Serving model
  # echo "  --> serving..."
  # conda run -p "$PATH_TO_ENV" ersilia -v serve "$model"
  
  # Send job to cluster
  N=$(ls "$PATH_TO_SMILES"/*.csv | wc -l)
  ssh acomajuncosa@irblogin02 \
    "sbatch --job-name='${model}' \
            --array=0-$((N-1-N+5)) \
            --output='$PATH_TO_ERSILIA/ersilia-models-chembl-irb/logs/${model}/%x_%a.out' \
            '$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts/3_2_job_submission.sh' \
            '$model' '$PATH_TO_ERSILIA' '$PATH_TO_SMILES' '$PATH_TO_RESULTS/${model}'"


done < "$PATH_TO_MODELS"