import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import torch, clip

schedules = {
    'uniform [.90,.90,.90]': [0.90, 0.90, 0.90],
    'C2A [.97,.90,.68]': [0.97, 0.90, 0.68],
    'A2C [.68,.90,.97]': [0.68, 0.90, 0.97],
    'mid_heavy [.90,.70,.95]': [0.90, 0.70, 0.95],
    'paper R=0.7 uniform [.70,.70,.70]': [0.70, 0.70, 0.70],
}

for name, sched in schedules.items():
    model, preprocess = clip.load('ViT-B/16', 'Ours-0.1', pruning_schedule=sched, device='cuda')
    model.eval()
    x = torch.randn(1, 3, 224, 224).cuda().half()
    counts = []

    def make_hook(i):
        def hook(module, inp, out):
            seq = out[0] if isinstance(out, tuple) else out
            counts.append((i, seq.shape[0]))
        return hook

    handles = []
    for i, blk in enumerate(model.visual.transformer.resblocks):
        handles.append(blk.register_forward_hook(make_hook(i)))
    try:
        with torch.no_grad():
            feat = model.encode_image(x)
        print(f'{name}: SUCCESS, final feature shape {feat.shape}')
    except Exception as e:
        print(f'{name}: CRASHED - {type(e).__name__}: {e}')
    print('  token counts per block:', counts)
    for h in handles:
        h.remove()
