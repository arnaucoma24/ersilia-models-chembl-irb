import argparse
import os

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Minimal parser for Ersilia batch runs")
    p.add_argument("--input_file", required=True, help="Path to input CSV/TSV")
    p.add_argument("--output_dir", required=True, help="Directory to write outputs")
    p.add_argument("--model", required=True, help="Model identifier")
    p.add_argument("--task_id", required=True, type=int, help="Task index")
    return p.parse_args()

# Parse arguments
args = parse_args()
input_file = args.input_file
output_dir = args.output_dir
model = args.model
task_id = args.task_id

# Create tmp dir
os.makedirs(os.path.join(output_dir, f"{model}_{str(task_id).zfill(3)}_tmp"), exist_ok=True)

# Read original smiles
original_smiles = [i.strip() for i in open(input_file, "r").readlines()]
header = original_smiles[0]
original_smiles = original_smiles[1:]

# Create split files
SPLIT_SIZE = 100
SPLIT_COUNTER = 0
for s in range(0, len(original_smiles), SPLIT_SIZE):
    # Avoid corner case
    if len(original_smiles[s: s+SPLIT_SIZE]) != 0:
        with open(os.path.join(output_dir, f"{model}_{str(task_id).zfill(3)}_tmp", f"split_{SPLIT_COUNTER}.csv"), "w") as smi_out:
            smi_out.write(header + "\n")
            smiles = [smi for smi in original_smiles[s: s+SPLIT_SIZE]]
            smi_out.write("\n".join(smiles))
            SPLIT_COUNTER += 1