#!/bin/bash -l
#SBATCH --job-name=tda-baseline
#SBATCH --gres=gpu:rtx3080:1
#SBATCH --partition=rtx3080
#SBATCH --time=02:00:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Part 1 - TDA baseline (Karmanov et al., CVPR 2024), the strongest training-free
# baseline TCA compares against in Table 1 (67.53% avg on the CD benchmark).
# Uses the official TDA repo cloned into baselines/TDA, pointed at the same
# data/ folder prepared for TCA (folder-naming symlinks + split jsons already
# set up to satisfy TDA's slightly different conventions - see PROJECT_STATUS.md).
#
# Run this from the TCA repo root: sbatch.tinygpu scripts/run_tda_baseline.sh

DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/ucf101"

export PATH="$WORK/conda_envs/TTA/bin:$PATH"  # bypass module system (namespace differs woody vs tinygpu) - use conda env python binaries directly

cd $WORK/prl/TCA/baselines/TDA
export TDA_RESULTS_CSV="$WORK/prl/TCA/results_tda.csv"
python tda_runner.py --config configs --datasets "$DATASETS" --data-root "$WORK/prl/TCA/data/" --backbone ViT-B/16

echo "TDA baseline run complete."
