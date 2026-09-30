#!/bin/bash -l
#SBATCH --job-name=tca-variance-check
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=v100
#SBATCH --time=00:30:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Diagnostic: run the EXACT same config (original code, TCA R=0.9, Caltech101) 3 times
# back-to-back to see whether results are stable (points to a systematic env/version gap
# vs. the paper) or highly variable (points to shuffle/seeding non-determinism as the
# main driver of the gap seen in the main comparison run). Safe to run in parallel with
# scripts/run_full_comparison.sh - separate job, separate GPU allocation, no shared state.

export PATH="$WORK/conda_envs/TTA/bin:$PATH"

cd "$WORK/prl/TCA_original"
CSV="$WORK/prl/TCA/variance_check.csv"

for i in 1 2 3; do
    echo "=== Run $i/3 ==="
    python runner.py --datasets caltech101 --token_pruning Ours-0.1 --results-csv "$CSV"
done

echo "Variance check complete - compare the 3 accuracy rows in variance_check.csv"
