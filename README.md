# TCA: Reproduction and Layer-Adaptive Pruning Extension

Course project for **Project Representation Learning** (FAU Erlangen-Nürnberg), built on top of the official code for:

> Z. Wang, D. Gong, S. Wang, Z. Huang, Y. Luo. **"Is Less More? Exploring Token Condensation as Training-free Test-time Adaptation."** ICCV 2025. [arXiv:2410.14729](https://arxiv.org/abs/2410.14729) — [official repository](https://github.com/Jo-wang/TCA)

The original authors' README is preserved unmodified at [README_ORIGINAL.md](README_ORIGINAL.md). This README documents only what this project adds on top of it.

## What this project does

1. **Reproduction**: runs the official TCA code (plus EViT, ToMe, and an independently wired-up TDA baseline) on real hardware, across 8 of the paper's 10 cross-dataset benchmark datasets, and compares against the paper's own reported numbers.
2. **Extension (gap proposal)**: replaces TCA's single, uniform per-layer token-retention ratio `R` with a layer-adaptive schedule `[R_L3, R_L6, R_L9]`, to test whether deferring aggressive pruning to later (more semantic) ViT layers outperforms the reverse ordering, or uniform pruning itself.

Full write-up, derivations, and discussion are in the accompanying seminar report (not included in this code repository).

## Environment setup

```bash
conda env create -f environment.yaml
conda activate TTA
```

Dataset preparation:

```bash
./download_datasets.sh
```

This downloads and lays out the 8 datasets used in this project (Caltech101, DTD, EuroSAT, FGVC Aircraft, Food101, Oxford Flowers, Oxford Pets, UCF101) under `data/`. Stanford Cars and SUN397 split files are included for completeness, but their official image hosts have been offline since 2023; both are excluded from all results in this project.

## Usage

Single entry point for every method and configuration:

```bash
python runner.py --datasets {dataset_name} --token_pruning {Method-Rate} --results-csv {path}

# Example: TCA at retention ratio 0.9 on DTD
python runner.py --datasets dtd --token_pruning Ours-0.1 --results-csv results.csv

# Layer-adaptive schedule (this project's extension): per-location retention at blocks 3, 6, 9
python runner.py --datasets dtd --token_pruning Ours-0.1 --pruning_schedule 0.95 0.88 0.78 --results-csv results.csv
```

`--pruning_schedule` is optional; omitting it reproduces the original code's behavior exactly (verified by a regression check — see below).

The TDA baseline uses its own entry point:

```bash
cd baselines/TDA
python tda_runner.py --config configs --datasets {dataset_list} --data-root ../../data/ --backbone ViT-B/16
```

## What was changed on top of the released code

**Five defects found and fixed** in the originally released repository (none affect the adaptation algorithm itself — only packaging and argument parsing):
1. CLIP's byte-pair-encoding vocabulary file (`clip/bpe_simple_vocab_16e6.txt.gz`), hard-required at import time, was missing from the repository.
2. `environment.yaml` pinned two PyPI packages (`autoattack`, `robustbench`) at version numbers that do not exist and that nothing in the code imports.
3. `datasets/eurosat.py` looked for a split file under a different capitalization than the one actually shipped by CoOp, which fails on a case-sensitive filesystem.
4. `runner.py`'s argument parser read an undefined attribute (`args.visualize_mask`), crashing every invocation.
5. `runner.py`'s `--token_pruning choices` list was self-inconsistent with its own default value and with the `Name-Rate` string format the model parses.

**One feature added**: a `--pruning_schedule R3 R6 R9` CLI flag, threaded through `clip/clip.py` → `clip/model.py` → `runner.py`, replacing TCA's single scalar retention ratio with an independent value per drop location (blocks 3, 6, 9). Reservoir maintenance, logits correction, and cross-head attention scoring are unchanged. Configuration details and the rationale behind each tested schedule are in `configs/pruning_schedules.yaml`.

**One architectural limitation documented, not previously noted in the paper**: TCA's coreset-merging step hardcodes its center count to `K=4`. Once any single layer's retention ratio drops below roughly two-thirds, the number of tokens routed around this 4-center bottleneck approaches zero, collapsing most of that layer's spatial information into four averaged tokens. This affects the paper's own uniform `R=0.7` configuration, not only this project's schedules. See `configs/pruning_schedules.yaml` and `scripts/` for the diagnostic tooling used to find this.

## Results summary

8-dataset average top-1 accuracy (%), CLIP ViT-B/16, single V100 GPU:

| Method | Paper (8-ds avg) | Ours (8-ds avg) | Delta |
|---|---|---|---|
| EViT R=0.9 | 65.31 | 68.32 | +3.01 pp |
| ToMe R=0.9 | 65.19 | 64.92 | −0.27 pp |
| TDA | 67.55 | 68.05 | +0.50 pp |
| TCA R=0.9 | 69.45 | 64.23 | −5.22 pp |

Layer-adaptive schedules (redesigned to avoid the collapse boundary above), 8-dataset average:

| Schedule | R at blocks [3, 6, 9] | Accuracy (%) |
|---|---|---|
| Uniform (baseline) | [0.90, 0.90, 0.90] | 64.23 |
| Conservative→Aggressive (C2A) | [0.95, 0.88, 0.78] | 60.33 |
| Mid-heavy | [0.90, 0.78, 0.87] | 53.65 |
| Aggressive→Conservative (A2C) | [0.78, 0.88, 0.95] | 46.91 |

C2A beats its exact mirror A2C on 8 of 8 datasets (directional hypothesis confirmed); no schedule matches or beats uniform pruning outright (stronger hypothesis not confirmed). Full per-dataset numbers are in `results_original.csv`, `results_gap_experiment.csv`, `results_gap_experiment_v2.csv`, and `results_tda.csv`; `comparison_report.md` is generated directly from them via `scripts/compare_results.py`.

## Reproducibility notes

- CLIP ViT-B/16 backbone, PyTorch 2.4.0, torchvision 0.19.0, Python 3.9.7.
- Fixed `seed=1` across Python, NumPy, and both CPU/CUDA Torch generators for every run.
- Batch size is effectively 1: all evaluated methods process test images sequentially in an online, streaming test-time-adaptation setting. No training or learning rate applies — every evaluated method (TCA, EViT, ToMe, TDA) is training-free.
- Reproduction and gap-experiment code paths were kept in separate `git worktree`s of the same commit history during development, so that regression checks compared byte-identical baseline code.

## Repository layout

```
clip/            CLIP model + TCA's token condensation logic (modified: pruning-schedule support)
datasets/        Per-dataset loaders (CoOp/TPT convention)
baselines/TDA/   TDA baseline (Karmanov et al., CVPR 2024), wired up to this project's data layout
configs/         Pruning-schedule definitions and root-cause notes
scripts/         SLURM job scripts and the results-comparison script
runner.py        Single entry point for all TCA/EViT/ToMe runs
results_*.csv    Raw per-run results backing every number in this README and the report
```

## Citation

If you use the underlying method, please cite the original paper:

```bibtex
@article{wang2024less,
  title={Is Less More? Exploring Token Condensation as Training-free Test-time Adaptation},
  author={Wang, Zixin and Gong, Dong and Wang, Sen and Huang, Zi and Luo, Yadan},
  journal={arXiv preprint arXiv:2410.14729},
  year={2024}
}
```
