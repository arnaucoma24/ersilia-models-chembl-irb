import argparse
import shutil
import csv
import sys
import os

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Minimal parser for Ersilia batch runs")
    p.add_argument("--input_file", required=True, help="Path to input CSV/TSV")
    p.add_argument("--output_dir", required=True, help="Directory to write outputs")
    p.add_argument("--model", required=True, help="Model identifier")
    p.add_argument("--task_id", required=True, type=int, help="Task index")
    p.add_argument("--path_to_ersilia", required=True, help="Path to ersilia repository")
    return p.parse_args()

# Parse arguments
args = parse_args()
input_file = args.input_file
output_dir = args.output_dir
model = args.model
task_id = args.task_id
PATH_TO_ERSILIA = args.path_to_ersilia

# Import ersilia function
sys.path.insert(0, os.path.join(PATH_TO_ERSILIA, "ersilia"))
from ersilia.utils.identifiers.compound import CompoundIdentifier
identifier = CompoundIdentifier()

# Read original smiles
original_smiles = [i.strip() for i in open(input_file, "r").readlines()]
header = original_smiles[0]
original_smiles = original_smiles[1:]

# Get number of splits
TMP_PATH = os.path.join(output_dir, f"{model}_{str(task_id).zfill(3)}_tmp")
NUMBER_OF_SPLITS = len([i for i in os.listdir(TMP_PATH) if i.startswith('results')])

# Create final file
with open(os.path.join(output_dir, f"{model}_{str(task_id).zfill(3)}.csv"), "w") as output_file:
    for numb in range(NUMBER_OF_SPLITS):
        split = os.path.join(TMP_PATH, f"split_{numb}.csv")
        results = os.path.join(TMP_PATH, f"results_{numb}.csv")
        with open(split, "r") as fs, open(results, "r") as fr:
            for c, (i,j) in enumerate(zip(fs, fr)):
                if c == 0 and numb == 0:
                    output_file.write("key," + i.strip() + "," + j)
                elif c != 0:
                    output_file.write(identifier.convert_smiles_to_checksum(i.strip()) + "," + i.strip() + "," + j)
                    
# Remove tmp dir
shutil.rmtree(os.path.join(output_dir, f"{model}_{str(task_id).zfill(3)}_tmp"))