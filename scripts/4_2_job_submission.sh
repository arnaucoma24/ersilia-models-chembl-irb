#!/bin/bash

#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH -p sbnb_cpu_sphr,sbnb_cpu_zen3

model="$1"
PATH_TO_ERSILIA="$2"
PATH_TO_SMILES="$3"
PATH_TO_RESULTS="$4"

# Change working directory
cd "$PATH_TO_ERSILIA/ersilia-models-chembl-irb/scripts"

# Loads default environment configuration
export SINGULARITYENV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH #/.singularity.d/libs
export SINGULARITY_BINDPATH="/home/sbnb:/aloy/home,/data/sbnb/data:/aloy/data,/data/sbnb/scratch:/aloy/scratch"

# Run inside the Singularity container
singularity exec --cleanenv \
  /apps/singularity/ood_images/docker_irb_intel-optimized-tensorflow-avx512-2.13-pip-conda-jupyter-v6.sif ./4_3_run.sh \
  "$model" "$PATH_TO_ERSILIA" "$PATH_TO_SMILES" "$PATH_TO_RESULTS" "$SLURM_ARRAY_TASK_ID"