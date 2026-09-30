#!/bin/bash -l
#SBATCH --job-name=tca-repro
#SBATCH --gres=gpu:a100:1
#SBATCH --partition=a100
#SBATCH --time=08:00:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Part 1 - Reproduction of the cross-dataset (CD) benchmark, Table 1 of the paper.
# Run this from the TCA repo root: sbatch.tinygpu scripts/run_reproduction.sh
#
# Datasets currently ready (9/10 - stanford_cars and sun397 still need manual
# download, see download_progress.log / DATA_STATUS.md):
DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/ucf101"
# once stanford_cars + sun397 are downloaded, switch to:
# DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/stanford_cars/sun397/ucf101"

export PATH="$WORK/conda_envs/TTA/bin:$PATH"  # bypass module system (namespace differs woody vs tinygpu) - use conda env python binaries directly

cd $WORK/prl/TCA

RESULTS_CSV="$WORK/prl/TCA/results_reproduction.csv"

echo "=== TCA (Ours), R=0.9 - the paper's headline result (68.69% avg in Table 1) ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --results-csv "$RESULTS_CSV"

echo "=== EViT baseline, R=0.9 ==="
python runner.py --datasets "$DATASETS" --token_pruning EViT-0.1 --results-csv "$RESULTS_CSV"

echo "=== ToME baseline (R=0.9, dpr=0.1 at drop_loc) ==="
python runner.py --datasets "$DATASETS" --token_pruning ToME-0.1 --results-csv "$RESULTS_CSV"

echo "Reproduction runs complete."
