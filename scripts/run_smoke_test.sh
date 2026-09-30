#!/bin/bash -l
#SBATCH --job-name=tca-smoke-test
#SBATCH --gres=gpu:v100:1
#SBATCH --partition=v100
#SBATCH --time=00:20:00
#SBATCH --export=NONE
#SBATCH --output=%x_%j.log
unset SLURM_EXPORT_ENV

# Quick sanity check before committing to the full 24h run (scripts/run_full_comparison.sh).
# Runs TCA (Ours, R=0.9) on just DTD (1692 images, one of the smaller datasets) using the
# ORIGINAL unmodified code. Should finish in a few minutes and print a final accuracy line
# that should land close to 46.16% (the paper's reported DTD number for TCA R=0.9).
#
# Run from the TCA repo root: sbatch.tinygpu scripts/run_smoke_test.sh
# This does NOT touch results_original.csv / results_gap_experiment.csv - it writes to its
# own smoke_test.csv so it can't interfere with the real run.

export PATH="$WORK/conda_envs/TTA/bin:$PATH"  # bypass module system (namespace differs woody vs tinygpu) - use conda env python binaries directly

cd "$WORK/prl/TCA_original"
python runner.py --datasets dtd --token_pruning Ours-0.1 --results-csv "$WORK/prl/TCA/smoke_test.csv"

echo "Smoke test complete - if you see a 'Final test accuracy' line above with no errors, the full job is safe to launch."
