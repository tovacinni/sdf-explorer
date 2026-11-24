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

"""Sample every SDF in data-files/sdf with the SDF Explorer and save .npz files.

Runs the explorer binary once per (pattern, SDF) and writes
<out>/<pattern>/<SDF>.bin (the explorer's output) and <out>/<pattern>/<SDF>.npz
with arrays `position` (N, 3), `distance` (N, 1) and `gradient` (N, 3).
The grid pattern also gets `volume` (r, r, r) indexed [x, y, z] and `axis`
(r,), the coordinate of lattice index i on every axis; the image pattern gets
`slice` (s, s) indexed [x, y] and `axis`.

The default binary is build/sdf-explorer-egl, which `icompile --egl --opt`
builds; it renders through EGL on the GPU and needs no display.
"""

import argparse
import glob
import os
import subprocess as sp

import numpy as np

import sdfdes

viewer_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def parse_methods(specs):
    methods = {}
    for spec in specs:
        name, count = spec.split(':')
        methods[name] = int(count)
    return methods


def lattice_arrays(method, size, dist):
    """Volume-shaped copies of the grid and image samples, indexed [x, y(, z)].

    grid.glsl writes lattice point (x, y, z) at sample index (z * r + y) * r + x,
    r the smallest integer with r^3 >= N, at coordinate -1 + 2i/(r-1) on each
    axis; image.glsl writes pixel (x, y) at index y * s + x, s = ceil(sqrt(N)).
    Lattice points beyond the N requested are NaN.
    """
    if method == 'grid':
        r = 1
        while r ** 3 < size:
            r += 1
        flat = np.full(r ** 3, np.nan, dtype=np.float32)
        flat[:size] = dist[:size, 0]
        return {'volume': flat.reshape(r, r, r).transpose(2, 1, 0),
                'axis': np.linspace(-1.0, 1.0, r, dtype=np.float32)}
    if method == 'image':
        s = int(np.ceil(np.sqrt(size)))
        flat = np.full(s * s, np.nan, dtype=np.float32)
        flat[:size] = dist[:size, 0]
        return {'slice': flat.reshape(s, s).transpose(1, 0),
                'axis': np.linspace(-1.0, 1.0, s, dtype=np.float32)}
    return {}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--explorer', default=os.path.join(viewer_path, 'build', 'sdf-explorer-egl'),
                        help='SDF Explorer executable')
    parser.add_argument('--out', default=os.path.join(viewer_path, 'samples'),
                        help='directory that receives <pattern>/<SDF>.bin and .npz')
    parser.add_argument('--methods', nargs='+', default=['rand:1000000', 'near:2000000', 'surface:2000000'],
                        help='<pattern>:<N> pairs; pattern is a file name in data-files/sampler')
    parser.add_argument('--shapes', nargs='*', default=None,
                        help='SDF base names; default is every file under data-files/sdf')
    args = parser.parse_args()

    explorer = os.path.abspath(args.explorer)
    out = os.path.abspath(args.out)
    methods = parse_methods(args.methods)
    shapes = args.shapes or sorted(os.path.splitext(os.path.basename(s))[0]
                                   for s in glob.glob(os.path.join(viewer_path, 'data-files', 'sdf', '*', '*.glsl')))

    for shape in shapes:
        for method, size in methods.items():
            cmd = [explorer, '--sample', str(size), method, shape, out]
            # The explorer finds its sampler and SDF shaders relative to its
            # working directory, which icompile fills next to the binary.
            sp.run(cmd, check=True, cwd=os.path.dirname(explorer), stdout=sp.DEVNULL, timeout=1800)

            bin_path = os.path.join(out, method, f'{shape}.bin')
            pos, dist, normal = sdfdes.deserialize(bin_path)
            if not bool((pos != 0).any()):
                raise RuntimeError(f'{bin_path} holds only zeros: the sampling dispatch did not run')
            np.savez(os.path.join(out, method, f'{shape}.npz'),
                     position=pos.numpy(), distance=dist.numpy(), gradient=normal.numpy(),
                     **lattice_arrays(method, size, dist.numpy()))
            print(f'{method:22s} {shape:16s} {size}', flush=True)


if __name__ == '__main__':
    main()
