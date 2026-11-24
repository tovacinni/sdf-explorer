# The MIT License (MIT)
# Copyright (c) 2021, NVIDIA CORPORATION.
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""Measure how exact each SDF is and write a per-shape table.

For every SDF the script runs the SDF Explorer with five samplers and compares
the raw sdf() with the true distance to the shape:

- grid at 200^3: marching cubes on it gives the reference surface. For a shape
  with no lattice point inside (a thin or unsigned shape) the reference is the
  surface sampler's ray-traced points instead.
- accuracy_pairs in [-2, 2]^3: |sdf| / true distance in three bands of true
  distance (near 0.02-0.05, mid 0.05-0.3, far >= 0.3), and jumps between
  points 0.01 apart.
- accuracy_far at radius 1-100: far-field behaviour.
- accuracy_ball: proves overestimation without the reference surface (see
  data-files/sampler/accuracy_ball.glsl).

A band counts as exact when |sdf| is within 5% of the true distance at more
than 90% of its points. A shape overestimates when the ball test finds a sign
change at 0.01% or more of the points inside the [-1, 1] cube.
"""

import argparse
import csv
import glob
import os
import subprocess as sp

import numpy as np
import trimesh
from scipy.spatial import cKDTree
from skimage import measure

viewer_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

BANDS = [('near', 0.02, 0.05), ('mid', 0.05, 0.3), ('far', 0.3, np.inf)]
GRID_RESOLUTION = 200
PAIR_SAMPLES = 800_000
FAR_SAMPLES = 250_000
BALL_SAMPLES = 4_000_000
SURFACE_SAMPLES = 2_000_000
REFERENCE_POINTS = 2_000_000
FAR_QUERY_POINTS = 50_000
EXACT_TOLERANCE = 0.05
EXACT_FRACTION = 0.9
NEAR_EXACT_FRACTION = 0.6
OVERESTIMATE_FRACTION = 1e-4
SLIGHT_LIMIT = 1e-3
JUMP_SLOPE = 2.0


def read_bin(path):
    with open(path, 'rb') as f:
        n = int(np.frombuffer(f.read(4), dtype='<u4')[0])
        pos = np.frombuffer(f.read(12 * n), dtype='<f4').reshape(n, 3)
        dist = np.frombuffer(f.read(4 * n), dtype='<f4')
    return pos, dist


def run_sampler(explorer, work, pattern, n, shape):
    path = os.path.join(work, pattern, f'{shape}.bin')
    if not os.path.exists(path):
        sp.run([explorer, '--sample', str(n), pattern, shape, work], check=True,
               cwd=os.path.dirname(explorer), stdout=sp.DEVNULL, stderr=sp.DEVNULL, timeout=3600)
    return read_bin(path)


def reference_points(explorer, work, shape, level):
    pos, dist = run_sampler(explorer, work, 'grid', GRID_RESOLUTION ** 3, shape)
    r = GRID_RESOLUTION
    vol = dist[: r ** 3].reshape(r, r, r).transpose(2, 1, 0)
    if (vol < level).mean() > 1e-4:
        # A lattice point exactly on the level set makes marching cubes emit zero-area faces.
        vol = np.where(vol == np.float32(level), np.float32(level + 1e-7), vol)
        spacing = 2.0 / (r - 1)
        verts, faces, _, _ = measure.marching_cubes(vol, level=level, spacing=(spacing,) * 3)
        mesh = trimesh.Trimesh(verts - 1.0, faces, process=False)
        return mesh.sample(REFERENCE_POINTS, seed=0).astype(np.float32), 'marching cubes'
    spos, _ = run_sampler(explorer, work, 'surface', SURFACE_SAMPLES, shape)
    return spos[np.isfinite(spos).all(1)], 'surface samples'


def measure_shape(explorer, work, shape, level):
    ref, ref_kind = reference_points(explorer, work, shape, level)
    tree = cKDTree(ref)
    row = {'sdf': shape, 'reference': ref_kind}

    pos, s = run_sampler(explorer, work, 'accuracy_pairs', PAIR_SAMPLES, shape)
    finite = np.isfinite(s)
    # Nearest distances below 0.3 are cheap; beyond that, query a random subset in full.
    d_true = tree.query(pos, workers=-1, distance_upper_bound=BANDS[1][2])[0]
    far = np.flatnonzero(~np.isfinite(d_true))
    keep = np.random.default_rng(0).choice(far, min(FAR_QUERY_POINTS, len(far)), replace=False)
    d_true[keep] = tree.query(pos[keep], workers=-1)[0]
    ratio = np.abs(s) / np.maximum(d_true, 1e-9)
    for name, lo, hi in BANDS:
        m = finite & np.isfinite(d_true) & (d_true >= lo) & (d_true < hi)
        r = ratio[m]
        row[f'exact_{name}'] = float((np.abs(r - 1) <= EXACT_TOLERANCE).mean()) if len(r) else float('nan')
        row[f'ratio_median_{name}'] = float(np.median(r)) if len(r) else float('nan')
    a, b = s[0::2], s[1::2]
    ok = np.isfinite(a) & np.isfinite(b)
    row['jump_fraction'] = float((np.abs(a[ok] - b[ok]) / 0.01 > JUMP_SLOPE).mean())
    row['nonfinite_fraction'] = float(1 - finite.mean())

    fpos, fs = run_sampler(explorer, work, 'accuracy_far', FAR_SAMPLES, shape)
    radius = np.linalg.norm(fpos, axis=1)
    ffin = np.isfinite(fs)
    beyond = ffin & (radius > 20)
    row['far_ratio_median'] = float(np.median(np.abs(fs[beyond]) / radius[beyond]))
    row['far_overestimate_fraction'] = float((fs[ffin] > radius[ffin] + np.sqrt(3) + 1e-3).mean())

    bpos, bs = run_sampler(explorer, work, 'accuracy_ball', BALL_SAMPLES, shape)
    in_cube = (np.abs(bpos) <= 1).all(1) & np.isfinite(bs)
    row['overestimate_fraction'] = float((bs[in_cube] < -1e-5).mean())
    row['measured'] = verdict(row)
    return row


def verdict(row):
    over = row['overestimate_fraction']
    if over >= SLIGHT_LIMIT:
        return 'overestimates'
    if over >= OVERESTIMATE_FRACTION:
        return 'slightly overestimates'
    near, mid, far = row['exact_near'], row['exact_mid'], row['exact_far']
    if near > EXACT_FRACTION and mid > EXACT_FRACTION and far > EXACT_FRACTION:
        return 'exact'
    if near > EXACT_FRACTION:
        return 'exact near the surface, conservative farther'
    if near > NEAR_EXACT_FRACTION:
        return 'near-exact near the surface, conservative farther'
    return 'conservative'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--explorer', default=os.path.join(viewer_path, 'build', 'sdf-explorer-egl'))
    parser.add_argument('--work', default=os.path.join(viewer_path, 'samples', 'accuracy'),
                        help='directory for the sampler outputs; existing outputs are reused')
    parser.add_argument('--out', default='sdf_accuracy.csv')
    parser.add_argument('--shapes', nargs='*', default=None)
    parser.add_argument('--level', action='append', default=['Mandelbulb=0.0005'],
                        help='<SDF>=<iso level> for the reference surface of an SDF whose inside is not negative')
    args = parser.parse_args()

    explorer = os.path.abspath(args.explorer)
    work = os.path.abspath(args.work)
    levels = {k: float(v) for k, v in (x.split('=') for x in args.level)}
    shapes = args.shapes or sorted(os.path.splitext(os.path.basename(s))[0]
                                   for s in glob.glob(os.path.join(viewer_path, 'data-files', 'sdf', '*', '*.glsl')))
    rows = []
    for shape in shapes:
        row = measure_shape(explorer, work, shape, levels.get(shape, 0.0))
        rows.append(row)
        print(f"{shape:14s} {row['measured']:48s} exact near/mid/far "
              f"{row['exact_near']:.2f}/{row['exact_mid']:.2f}/{row['exact_far']:.2f}  "
              f"overestimate {100 * row['overestimate_fraction']:.3f}%  jumps {100 * row['jump_fraction']:.2f}%",
              flush=True)
    with open(args.out, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == '__main__':
    main()
