#!/bin/bash -e
OUTPUT_PREFIX="$1"
RESULT_DIR="`dirname "$(realpath "$OUTPUT_PREFIX")"`/" # The slash at the end is needed to work around an issue in Bis-tools
HCG_BW_FILE="$2"
GCH_BW_FILE="$3"
cp "$4" "$RESULT_DIR" # Needed to work around issues with paths in Bis-tools
NDR_BED="`basename "$4"`"
SAMPLE_NAME="$5"
CATEGORY_NAME="$6"

# This is needed to work around issues with paths in Bis-tools
cd "$RESULT_DIR"
ln -sf "$HCG_BW_FILE" HCG.bw
ln -sf "$GCH_BW_FILE" GCH.bw
HCG_BW_FILE_LINK="`pwd`/HCG.bw"
GCH_BW_FILE_LINK="`pwd`/GCH.bw"

# Make Samples.txt
cat << EOF > Samples.txt
$HCG_BW_FILE_LINK	.	percentage
$GCH_BW_FILE_LINK	.	percentage
EOF

# Note: lengends and prefixs are spelled incorrectly in the Bis-tools code
# Density plot
perl "$BISTOOLS/alignWigToBed.pl" --density_bar --enrich_max 4.0 --result_dir "$RESULT_DIR" --prefixs "$OUTPUT_PREFIX" --locs "$NDR_BED" --category_names "$CATEGORY_NAME" --sample_names "$SAMPLE_NAME" --experiment_names Methylation --experiment_names Accessibility --rep_num_experiments 1 --rep_num_experiments 1 Samples.txt
