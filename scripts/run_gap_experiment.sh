#!/bin/bash -l
#SBATCH --job-name=tca-gap-exp
#SBATCH --gres=gpu:a100:1
#SBATCH --partition=a100
#SBATCH --time=12:00:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Part 2 - Gap Proposal: Layer-Adaptive Pruning Rates in TCA.
# Runs all 4 schedules from configs/pruning_schedules.yaml across the CD benchmark.
# Run this from the TCA repo root: sbatch.tinygpu scripts/run_gap_experiment.sh

DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/ucf101"
# add stanford_cars/sun397 once downloaded (see DATA_STATUS.md)

export PATH="$WORK/conda_envs/TTA/bin:$PATH"  # bypass module system (namespace differs woody vs tinygpu) - use conda env python binaries directly

cd $WORK/prl/TCA

RESULTS_CSV="$WORK/prl/TCA/results_gap_experiment.csv"

echo "=== Uniform (baseline): R = [0.90, 0.90, 0.90] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.90 0.90 0.90 --results-csv "$RESULTS_CSV"

echo "=== Conservative-to-Aggressive (C2A, proposed): R = [0.97, 0.90, 0.68] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.97 0.90 0.68 --results-csv "$RESULTS_CSV"

echo "=== Aggressive-to-Conservative (A2C, control): R = [0.68, 0.90, 0.97] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.68 0.90 0.97 --results-csv "$RESULTS_CSV"

echo "=== Mid-heavy: R = [0.90, 0.70, 0.95] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.90 0.70 0.95 --results-csv "$RESULTS_CSV"

echo "Gap experiment runs complete."
