#!/usr/bin/env bash
set -euo pipefail

# ---- Paths (edit if your layout changes) ----
PATH_TO_ERSILIA="/aloy/home/acomajuncosa/Ersilia"
PATH_TO_MODELS="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/ersilia_models.txt"  # ersilia models listed
PATH_TO_EMH="$PATH_TO_ERSILIA/ErsiliaModelHub"  # ersilia models cloned
PATH_TO_ENV="$PATH_TO_ERSILIA/envs/ersilia"  # ersilia package
PATH_TO_SMILES="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/data/splits"  # splits of 10k compounds
PATH_TO_RESULTS="$PATH_TO_ERSILIA/ersilia-models-chembl-irb/results"
PATH_TO_CUSTOM_ENV_DIR="$PATH_TO_ERSILIA/envs"

# Ensure custom envs directory exists
mkdir -p "$PATH_TO_CUSTOM_ENV_DIR"

# ---- Change working directory ----
cd "$PATH_TO_ERSILIA"

# ---- Create/ensure env (Python 3.10) ----
if [ ! -d "$PATH_TO_ENV" ]; then
  conda create -p "$PATH_TO_ENV" -y python=3.10
fi

# ---- Clone (or re-clone) ersilia repo ----
if [ -d "$PATH_TO_ERSILIA/ersilia" ]; then
  echo "[ersilia] removing existing repo..."
  rm -rf "$PATH_TO_ERSILIA/ersilia"
fi
echo "[ersilia] cloning fresh..."
git clone --depth=1 https://github.com/ersilia-os/ersilia.git "$PATH_TO_ERSILIA/ersilia"

# ---- Install ersilia in the *conda env* ----
echo "[ersilia] installing in conda env..."
conda run -p "$PATH_TO_ENV" python -m pip install -U pip setuptools wheel
conda run -p "$PATH_TO_ENV" python -m pip install -e "$PATH_TO_ERSILIA/ersilia"
echo "[ersilia] printing ersilia help..."
conda run -p "$PATH_TO_ENV" ersilia --help

# ---- Clean eos folder if needed ----
EOS_DIR="$HOME/eos"
if [ -d "$EOS_DIR" ]; then
  echo "[ersilia] removing $EOS_DIR..."
  rm -rf -- "$EOS_DIR"
fi

# ---- Clone models listed in file ----
mkdir -p "$PATH_TO_EMH"
cd "$PATH_TO_EMH"

# ---- Get list of models to work with ----
mapfile -t models < "$PATH_TO_MODELS"

# ensure conda-pack is available (once)
CONDA_BASE="$(conda info --base)"  # e.g. /home/acomajuncosa/programs/anaconda3
echo "[conda-pack] ensuring conda-pack is installed..."
conda run -n base python -m pip install --no-cache-dir --upgrade conda-pack

for model in "${models[@]}"; do
  [[ -z "${model// }" || "$model" =~ ^# ]] && continue
  echo "[model] $model"

  # Check which models are already fetched
  conda run -p "$PATH_TO_ENV" ersilia catalog

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
  # this command will automatically create a conda environment.

  # --- Move the freshly-built env to /aloy using conda-pack ---
  
  LOCAL_ENV_DIR="$CONDA_BASE/envs/$model"  # env created by ersilia fetch
  SHARED_ENV_DIR="$PATH_TO_CUSTOM_ENV_DIR/$model"  # /aloy/home/acomajuncosa/Ersilia/envs/<MODEL>
  PKG_TAR="$SHARED_ENV_DIR.tar.gz"

  echo "  --> packing local env with conda-pack"
  # write tarball to /aloy (saves /home space)
  mkdir -p "$PATH_TO_CUSTOM_ENV_DIR"
  conda run -n base conda-pack -p "$LOCAL_ENV_DIR" -o "$PKG_TAR" --ignore-missing-files

  echo "  --> unpacking env on shared FS: $SHARED_ENV_DIR"
  mkdir -p "$SHARED_ENV_DIR"
  tar -xzf "$PKG_TAR" -C "$SHARED_ENV_DIR"

  # fix prefixes/paths inside the unpacked env
  "$SHARED_ENV_DIR/bin/conda-unpack"

  # cleanup
  rm -f "$PKG_TAR"

  # Remove the local env to avoid confusion
  conda run -n base conda env remove -p "$LOCAL_ENV_DIR" -y || true
  echo "  --> shared env ready at: $SHARED_ENV_DIR"
  
  # Create output directory
  mkdir -p "$PATH_TO_RESULTS/${model}"

  # Create logs directory
  mkdir -p "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/logs/${model}"
  
  # Send job to cluster
  N=$(ls "$PATH_TO_SMILES"/*.csv | wc -l)
  ssh acomajuncosa@irblogin02 \
    "sbatch --job-name='${model}' \
            --array=0-$((N-1))%10 \
            --output='$PATH_TO_ERSILIA/ersilia-models-chembl-irb/logs/${model}/${model}_%03a.out' \
            '$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts/4_2_job_submission.sh' \
            '$model' '$PATH_TO_ERSILIA' '$PATH_TO_SMILES' '$PATH_TO_RESULTS/${model}'"


done