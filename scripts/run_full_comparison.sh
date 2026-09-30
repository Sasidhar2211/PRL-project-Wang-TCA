#!/bin/bash -l
#SBATCH --job-name=tca-full-comparison
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=v100
#SBATCH --time=08:00:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# One-shot comparison job on a V100 (switched from A100: your account's A100 group
# quota is currently maxed out by other course users - AssocGrpGRES - while V100 was
# free and the smoke test showed it finishes DTD's 1692 images in ~1 minute, so the
# full 8-dataset x 8-config sweep below should comfortably finish in a few hours,
# well under the 8h cap requested):
#   1. ORIGINAL unmodified TCA code (git worktree at ../TCA_original, HEAD 1fa99f5)
#      -> checks whether the paper's own code reproduces the paper's own Table 1 numbers.
#   2. MODIFIED code (this repo) with the 4 gap-proposal pruning schedules, including
#      "uniform" R=[0.90,0.90,0.90] which is numerically identical to step 1's Ours-0.1
#      run - this doubles as the regression check that our schedule refactor didn't
#      change behavior when no schedule is passed.
#   3. TDA baseline (official repo, pointed at our data/) for the strongest published
#      training-free comparison point.
#   4. A comparison report against the paper's own reported numbers.
#
# Every step writes to CSV as it goes, so if this runs out of wall-clock time, whatever
# finished is still safely on disk - check results_original.csv / results_gap_experiment.csv.
#
# Run from the TCA repo root: sbatch.tinygpu scripts/run_full_comparison.sh
# (If your account doesn't have the a100 partition, drop the two #SBATCH lines above
#  and use plain --gres=gpu:1 to let the scheduler pick any free GPU.)

DATASETS="caltech101/dtd/eurosat/fgvc/food101/oxford_flowers/oxford_pets/ucf101"
ROOT="$WORK/prl/TCA"

export PATH="$WORK/conda_envs/TTA/bin:$PATH"  # bypass module system (namespace differs woody vs tinygpu) - use conda env python binaries directly

echo "################################################################"
echo "# STEP 1/3 - Original unmodified TCA code (reproduction of Table 1)"
echo "################################################################"
cd "$ROOT/../TCA_original"
ORIG_CSV="$ROOT/results_original.csv"

echo "=== [original] TCA (Ours), R=0.9 ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --results-csv "$ORIG_CSV"

echo "=== [original] EViT, R=0.9 ==="
python runner.py --datasets "$DATASETS" --token_pruning EViT-0.1 --results-csv "$ORIG_CSV"

echo "=== [original] ToME, R=0.9 ==="
python runner.py --datasets "$DATASETS" --token_pruning ToME-0.1 --results-csv "$ORIG_CSV"

echo "################################################################"
echo "# STEP 2/3 - Modified code: gap-proposal pruning schedules"
echo "################################################################"
cd "$ROOT"
GAP_CSV="$ROOT/results_gap_experiment.csv"

echo "=== [modified] Uniform (baseline): R = [0.90, 0.90, 0.90] - sanity check vs step 1 ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.90 0.90 0.90 --results-csv "$GAP_CSV"

echo "=== [modified] Conservative-to-Aggressive (C2A, proposed): R = [0.97, 0.90, 0.68] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.97 0.90 0.68 --results-csv "$GAP_CSV"

echo "=== [modified] Aggressive-to-Conservative (A2C, control): R = [0.68, 0.90, 0.97] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.68 0.90 0.97 --results-csv "$GAP_CSV"

echo "=== [modified] Mid-heavy: R = [0.90, 0.70, 0.95] ==="
python runner.py --datasets "$DATASETS" --token_pruning Ours-0.1 --pruning_schedule 0.90 0.70 0.95 --results-csv "$GAP_CSV"

echo "################################################################"
echo "# STEP 3/3 - TDA baseline (official repo, our data)"
echo "################################################################"
cd "$ROOT/baselines/TDA"
export TDA_RESULTS_CSV="$ROOT/results_tda.csv"
python tda_runner.py --config configs --datasets "$DATASETS" --data-root "$ROOT/data/" --backbone ViT-B/16

echo "################################################################"
echo "# Building comparison report"
echo "################################################################"
cd "$ROOT"
python scripts/compare_results.py

echo "Full comparison run complete."
