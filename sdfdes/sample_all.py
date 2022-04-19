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

import os
import torch
import subprocess as sp 
import sdfdes
import polyscope as ps
import glob
import numpy as np

# Paths
viewer_path = os.path.abspath('../')
sample_path = os.path.join(viewer_path, 'samples')
methods = {'rand': 1000000, 'near': 2000000, 'surface': 2000000}
shape = 'Fish'

shader_path = "data-files/sdf"
shaders = glob.glob(os.path.join(viewer_path, shader_path, "**/*.glsl"))

for shader in shaders:
    for method in methods:
        size = methods[method]
        shape = os.path.splitext(os.path.basename(shader))[0]
        dist_path = os.path.join(sample_path, f'{method}/{shape}.bin')
        cmd = f'icompile --run --sample {size} {method} {shape} {sample_path}'

        # Sample points using the G3D SDF explorer
        proc = sp.check_output(cmd.split(), shell=False, cwd=viewer_path)

        pos, dist, normal = sdfdes.deserialize(dist_path)
        out_path = os.path.join(sample_path, f'{method}/{shape}.npz')
        np.savez(out_path, position=pos.numpy(), distance=dist.numpy(), gradient=normal.numpy())

