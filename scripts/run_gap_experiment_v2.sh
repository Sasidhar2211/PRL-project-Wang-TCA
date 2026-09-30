#!/bin/bash -l
#SBATCH --job-name=tca-gap-v2
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=v100
#SBATCH --time=04:00:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Revised gap-proposal schedules (see configs/pruning_schedules.yaml for the full
# root-cause writeup). The v1 schedules (C2A/A2C/mid-heavy as originally proposed)
# caused catastrophic near-random accuracy because they push a single layer's
# retention rate below the ~0.67 stability floor of TCA's coreset-merge arithmetic.
# These v2 schedules preserve each schedule's qualitative shape while keeping every
# layer safely inside the model's working range (validated via
# scripts/debug_schedule_shapes.py before spending GPU time on them).
#
# Run from the TCA repo root: sbatch.tinygpu scripts/run_gap_experiment_v2.sh

DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/ucf101"
RESULTS_CSV="$WORK/prl/TCA/results_gap_experiment_v2.csv"

export PATH="$WORK/conda_envs/TTA/bin:$PATH"
cd "$WORK/prl/TCA"

echo "=== C2A v2: R = [0.95, 0.88, 0.78] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.95 0.88 0.78 --results-csv "$RESULTS_CSV"

echo "=== A2C v2: R = [0.78, 0.88, 0.95] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.78 0.88 0.95 --results-csv "$RESULTS_CSV"

echo "=== Mid-heavy v2: R = [0.90, 0.78, 0.87] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.90 0.78 0.87 --results-csv "$RESULTS_CSV"

echo "Gap experiment v2 complete."
