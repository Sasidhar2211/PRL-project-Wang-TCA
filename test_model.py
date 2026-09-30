import torch
import clip

print("Testing model load with pruning_schedule...")
model, preprocess = clip.load("ViT-B/16", token_pruning="Ours-0.1", pruning_schedule=[0.97, 0.90, 0.68], device="cpu")

dpr = model.visual.transformer.dpr

print("drop rates:", dpr)
print("dpr[3]:", dpr[3])
print("dpr[6]:", dpr[6])
print("dpr[9]:", dpr[9])

assert abs(dpr[3] - (1.0 - 0.97)) < 1e-5
assert abs(dpr[6] - (1.0 - 0.90)) < 1e-5
assert abs(dpr[9] - (1.0 - 0.68)) < 1e-5

print("Success! Layer-adaptive pruning schedule is working as expected.")

print("\nTesting default (no schedule, uniform) fallback still works...")
model2, _ = clip.load("ViT-B/16", token_pruning="Ours-0.1", device="cpu")
dpr2 = model2.visual.transformer.dpr
assert abs(dpr2[3] - 0.1) < 1e-5
assert abs(dpr2[6] - 0.1) < 1e-5
assert abs(dpr2[9] - 0.1) < 1e-5
print("Success! Uniform fallback (drop_rate=0.1 at all locations) still works.")
