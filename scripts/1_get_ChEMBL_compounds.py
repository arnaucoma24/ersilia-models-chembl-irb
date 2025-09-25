from rdkit import Chem
import pandas as pd
import psycopg
from tqdm import tqdm
import os


# root = os.path.dirname(os.path.abspath(__file__))
root = "."

def export_query(conn, sql: str, outfile: str) -> None:
    os.makedirs(os.path.dirname(outfile), exist_ok=True)
    print(f"Exporting query -> {outfile}")
    with conn.cursor() as cur, open(outfile, "w", encoding="utf-8", newline="") as f:
        with cur.copy(f"COPY ({sql}) TO STDOUT WITH (FORMAT csv, HEADER true)") as copy:
            for data in copy:
                f.write(data.tobytes().decode("utf-8"))

def export_chembl_structures(conn, outfile):
    sql = """
    SELECT md.chembl_id,
           cs.standard_inchi_key,
           cs.canonical_smiles
    FROM molecule_dictionary md
    JOIN compound_structures cs
      ON md.molregno = cs.molregno
    ORDER BY cs.standard_inchi_key
    """
    export_query(conn, sql, outfile)


# Define output file
outfile = os.path.join(root, "..", "data", "ChEMBL_v36.csv")

# Run query
with psycopg.connect(
    dbname="chembl_36",
    user="chembl_user",
    password="aaa",
    host="localhost",
    port=5432,
) as conn:
    export_chembl_structures(conn, outfile)

# Reading ChEMBL data
ChEMBL_data = pd.read_csv(outfile)
print(f"Number of ChEMBL compounds: {len(ChEMBL_data)}")


# Remove rdkit-failed molecules -- None of them fail!
print("Removing rdkit-failed molecules")
smiles = ChEMBL_data['canonical_smiles'].tolist()
failed = []
for smi in tqdm(smiles):
    mol = Chem.MolFromSmiles(smi)
    if mol == None:
        failed.append(True)
    else:
        failed.append(False)
ChEMBL_data['rdkit-failed'] = failed
ChEMBL_data = ChEMBL_data[ChEMBL_data['rdkit-failed'] == False].reset_index(drop=True)
print(f"Number of ChEMBL compounds (after rdkit failures): {len(ChEMBL_data)}")

# Creating splits
split_size = 10000
ChEMBL_data["split"] = (ChEMBL_data.index // split_size).astype(str).str.zfill(3)

# Get splits
splits = sorted(set(ChEMBL_data['split']))

print(f"Splitting compounds - split_size: {split_size}")

# Create splits directory
os.makedirs(os.path.join(root, "..", "data", "splits"), exist_ok=True)

# For each split
for split in splits:

    # Create split file
    df = pd.DataFrame()
    df['smiles'] = ChEMBL_data[ChEMBL_data['split'] == split]['canonical_smiles'].tolist()
    df.to_csv(os.path.join(root, "..", "data", "splits", f"ChEMBL_{split}.csv"), index=False)