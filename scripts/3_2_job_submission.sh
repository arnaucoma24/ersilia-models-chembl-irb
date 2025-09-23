#!/bin/bash

#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --array=0-827%3
#SBATCH --cpus-per-task=8
#SBATCH --mem=4G
#SBATCH --output=./processed/unidock_docking/training_outputs/%x_%a.out
#SBATCH -p sbnb_cpu_sphr,sbnb_cpu_zen3