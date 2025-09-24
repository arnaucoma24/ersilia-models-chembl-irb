#!/usr/bin/env bash
# copy_dir.sh

SOURCE="./../data"
DEST="/aloy/home/acomajuncosa/Ersilia/ersilia-models-chembl-irb/data"

mkdir -p "$DEST"
cp -r "$SOURCE"/* "$DEST"/

echo "Copied contents of $SOURCE -> $DEST"


# Copy Ersilia models as well