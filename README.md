## A Dataset and Explorer for 3D Signed Distance Functions

This is the official code repository for our JCGT paper on a new SDF dataset:

[A Dataset and Explorer for 3D Signed Distance Functions (JCGT/I3D 2022)](https://tovacinni.github.io/sdf-explorer)

[Towaki Takikawa](https://tovacinni.github.io), [Andrew Glassner](https://www.glassner.com), 
[Morgan McGuire](https://casual-effects.com)

<img src="media/demo.jpg" alt="drawing" height="400"/>

In this work we provide a dataset and an explorer to visualize, analyze and work with signed distance functions (SDFs). We currently have 63 SDFs, and hopefully more in the future!

If you have any feature requests, feel free to submit an issue!

## Downloading the Dataset

Our dataset is available [here](https://drive.google.com/drive/folders/10DcbQqtVoAv7oLBEdPtr16E5J23jfNKg)
(17 GB). It samples all 63 SDFs with each of the eight samplers in `data-files/sampler`; each sampler
is one zip, `sdf-explorer-<sampler>.zip`, holding `<sampler>/<SDF>.npz` for every shape:

| Sampler | Points per shape |
|---|---|
| `rand` (uniform in the [-1, 1] cube) | 1M |
| `near` (surface points moved along the gradient by N(0, 0.005²)) | 2M |
| `surface` (on the zero level set) | 2M |
| `grid` (100³ lattice over [-1, 1]³) | 1M |
| `jitter` (the grid lattice, jittered within half a cell) | 1M |
| `image` (1000² lattice on the z = 0 plane) | 1M |
| `metropolis` (Metropolis–Hastings toward the surface) | 1M |
| `metropolis_curvature` (Metropolis–Hastings toward high curvature) | 1M |

The `surface` and `near` samples, and the starting point of `metropolis_curvature`, are NaN where 100
random rays all missed the shape.

To load the `.npz` files, you can simply do:

```python
import numpy as np
npz_file = np.load("Snail.npz")
position = npz_file['position']  # (N, 3)
distance = npz_file['distance']  # (N, 1)
gradient = npz_file['gradient']  # (N, 3)
```

The `grid` files also hold `volume`, the distances as an (r, r, r) array indexed `[x, y, z]`, and
`axis`, the coordinate of index i on every axis; the `image` files hold `slice`, indexed `[x, y]`, and
`axis`.

## Measured Accuracy of Each SDF

Table 1 of the paper labels each SDF exact (E) or conservative (C). We measured every SDF against
its true distance field; 26 of the 63 do not match their label, and some overestimate distance,
which breaks sphere tracing and the `surface` and `near` samplers.

For each SDF, `sdfdes/classify_sdfs.py` runs the explorer and compares the raw `sdf()` with the
distance to a reference surface:

- The reference surface is marching cubes on a 200³ `grid` sample. For an SDF with no grid point
  inside it (Bezier, Triangle, Serpinski) it is the `surface` sampler's points instead.
- `accuracy_pairs` samples 800k points in [-2, 2]³. "Exact within 5%" is the fraction of points
  whose |sdf| is within 5% of the true distance, in three bands of true distance: near
  (0.02–0.05), mid (0.05–0.3) and far (0.3 and up). Points come in pairs 0.01 apart, and a pair
  whose values differ by more than 0.02 is a jump.
- `accuracy_ball` proves overestimation without the reference surface: it picks a point p and a
  point q inside the ball of radius 0.95·|sdf(p)| around p, and checks whether sdf changes sign
  between them. "Proven overestimate" is the fraction of points inside the [-1, 1] cube where
  it does.
- `accuracy_far` samples radius 1 to 100 for the far field.

"Exact" means more than 90% of points are within 5% of the true distance in all three bands. An
SDF overestimates when the sign test fails at 0.1% or more of the points, and slightly
overestimates from 0.01%; rates near these cutoffs vary by a few hundredths of a percent between
runs. To rerun the measurement on the EGL build:

```
cd sdfdes
pip install -r requirements.txt
python classify_sdfs.py --out sdf_accuracy.csv
```

| SDF | Table 1 | Measured | Exact within 5% (near / mid / far) | Proven overestimate | Notes |
|---|---|---|---|---|---|
| Bezier | E | exact | 1.00 / 1.00 / 1.00 | 0.000% | reference: surface samples |
| Boat | C | overestimates | 0.00 / 0.02 / 0.09 | 0.563% | jumps at 0.05% of point pairs |
| Burger | C | slightly overestimates | 0.09 / 0.05 / 0.20 | 0.055% | jumps at 0.86% of point pairs |
| Cables | C | conservative | 0.04 / 0.02 / 0.00 | 0.002% | jumps at 0.07% of point pairs |
| Capsule | E | exact | 1.00 / 1.00 / 1.00 | 0.000% |  |
| Castle | C | overestimates | 0.00 / 0.00 / 0.00 | 0.409% | jumps at 0.15% of point pairs; 0.22× the distance beyond radius 20 |
| Chain | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% | jumps at 0.22% of point pairs |
| Cheese | C | near-exact near the surface, conservative farther | 0.82 / 0.69 / 0.04 | 0.003% |  |
| Cone | E | exact near the surface, conservative farther | 0.98 / 0.90 / 0.76 | 0.000% |  |
| Cube | E | exact | 0.99 / 1.00 / 1.00 | 0.000% |  |
| Cybertruck | C | conservative | 0.07 / 0.14 / 0.00 | 0.006% |  |
| Cylinder | E | exact | 0.99 / 1.00 / 1.00 | 0.000% |  |
| Dalek | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% | jumps at 0.10% of point pairs; too large beyond radius 20 at 0.1% of points |
| Dinosaur | C | conservative | 0.38 / 0.36 / 0.30 | 0.000% | jumps at 0.13% of point pairs |
| Dodecahedron | E | exact near the surface, conservative farther | 0.97 / 0.88 / 0.56 | 0.000% |  |
| Elephant | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% |  |
| Fish | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% | 0.25× the distance beyond radius 20 |
| Gear | C | near-exact near the surface, conservative farther | 0.88 / 0.63 / 0.29 | 0.000% | jumps at 0.18% of point pairs |
| Girl | C | overestimates | 0.01 / 0.01 / 0.13 | 12.586% | jumps at 27.12% of point pairs |
| GrandPiano | C | slightly overestimates | 0.52 / 0.79 / 0.85 | 0.019% | jumps at 0.50% of point pairs |
| Helix | E | conservative | 0.17 / 0.02 / 0.00 | 0.001% |  |
| Hexprism | E | exact | 0.98 / 1.00 / 1.00 | 0.000% |  |
| HumanHead | C | conservative | 0.28 / 0.35 / 0.03 | 0.000% |  |
| HumanSkull | C | near-exact near the surface, conservative farther | 0.68 / 0.83 / 0.14 | 0.000% | 0.02× the distance beyond radius 20 |
| Icosahedron | E | exact near the surface, conservative farther | 0.97 / 0.94 / 0.79 | 0.000% |  |
| Jellyfish | E | conservative | 0.01 / 0.00 / 0.00 | 0.000% | jumps at 0.42% of point pairs |
| Jetfighter | C | conservative | 0.08 / 0.03 / 0.00 | 0.005% |  |
| Julia | E | slightly overestimates | 0.01 / 0.00 / 0.01 | 0.100% | too large beyond radius 20 at 53.0% of points |
| Key | C | near-exact near the surface, conservative farther | 0.81 / 0.69 / 0.30 | 0.000% |  |
| Knob | E | near-exact near the surface, conservative farther | 0.69 / 0.52 / 0.20 | 0.000% |  |
| Lamborghini | C | slightly overestimates | 0.66 / 0.63 / 0.70 | 0.098% | jumps at 0.20% of point pairs |
| Mandelbulb | E | slightly overestimates | 0.00 / 0.00 / 0.33 | 0.012% | jumps at 0.17% of point pairs |
| MantaRay | C | conservative | 0.00 / 0.00 / 0.00 | 0.001% | 0.22× the distance beyond radius 20 |
| Mech | C | overestimates | 0.01 / 0.01 / 0.05 | 32.402% | jumps at 48.42% of point pairs; NaN/inf at 0.15% of points |
| Menger | E | conservative | 0.04 / 0.55 / 0.49 | 0.000% |  |
| Mobius | E | conservative | 0.41 / 0.57 / 0.52 | 0.000% | jumps at 0.47% of point pairs |
| Mountain | C | conservative | 0.50 / 0.48 / 0.03 | 0.001% | jumps at 0.17% of point pairs |
| Mushroom | C | conservative | 0.01 / 0.02 / 0.00 | 0.000% | jumps at 0.22% of point pairs; 0.12× the distance beyond radius 20 |
| Octabound | C | exact near the surface, conservative farther | 0.91 / 0.69 / 0.48 | 0.000% |  |
| Octahedron | E | exact | 0.95 / 0.99 / 1.00 | 0.000% |  |
| Oldcar | C | slightly overestimates | 0.17 / 0.33 / 0.32 | 0.010% | jumps at 0.24% of point pairs |
| PixarMike | C | conservative | 0.12 / 0.07 / 0.00 | 0.002% | jumps at 0.19% of point pairs |
| Pyramid | E | overestimates | 0.69 / 0.76 / 0.97 | 2.221% |  |
| Rock | E | conservative | 0.05 / 0.01 / 0.00 | 0.002% |  |
| Rooks | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% |  |
| Roundbox | E | exact | 1.00 / 1.00 / 1.00 | 0.000% |  |
| Serpinski | E | exact | 1.00 / 1.00 / 1.00 | 0.000% | reference: surface samples |
| Snail | E | near-exact near the surface, conservative farther | 0.63 / 0.69 / 0.33 | 0.009% |  |
| Snake | C | slightly overestimates | 0.28 / 0.35 / 0.06 | 0.029% | 0.02× the distance beyond radius 20 |
| Sphere | E | exact | 1.00 / 1.00 / 1.00 | 0.000% |  |
| Spike | C | near-exact near the surface, conservative farther | 0.82 / 0.72 / 0.45 | 0.002% |  |
| Tardigrade | C | conservative | 0.24 / 0.15 / 0.00 | 0.000% | jumps at 4.62% of point pairs |
| Teapot | E | conservative | 0.02 / 0.01 / 0.00 | 0.000% |  |
| Temple | C | conservative | 0.00 / 0.01 / 0.00 | 0.003% | jumps at 0.14% of point pairs |
| Tetrahedron | E | exact near the surface, conservative farther | 0.95 / 0.78 / 0.38 | 0.000% |  |
| TieFighter | E | near-exact near the surface, conservative farther | 0.66 / 0.67 / 0.37 | 0.002% |  |
| Torus | E | exact | 1.00 / 1.00 / 1.00 | 0.000% |  |
| Tree | C | conservative | 0.08 / 0.13 / 0.01 | 0.010% | jumps at 0.57% of point pairs |
| Trefoil | C | conservative | 0.00 / 0.00 / 0.00 | 0.000% | 0.16× the distance beyond radius 20 |
| Triangle | E | exact | 1.00 / 1.00 / 1.00 | 0.000% | reference: surface samples |
| Triprismbound | C | exact near the surface, conservative farther | 0.93 / 0.70 / 0.27 | 0.000% |  |
| UprightPiano | C | conservative | 0.55 / 0.80 / 0.70 | 0.001% | jumps at 1.01% of point pairs |
| Vase | E | conservative | 0.41 / 0.60 / 0.67 | 0.004% |  |

## Build Instructions for the Interactive Explorer

### G3D Innovation Engine

Our explorer depends on the [G3D Innovation Engine](https://casual-effects.com/g3d/). 

Refer to [the G3D build guide](https://casual-effects.com/g3d/G3D10/readme.md.html?) to install G3D for the appropriate OS.

### Downloading Matcaps

For the code to properly run, you will need to download a few matcap files. To download matcaps:

```
pip install wget
python download_matcaps.py
git lfs pull
```

Alternatively, if you have your own matcaps or download matcaps yourself from the internet, you can 
place them in `data-files/matcap/categoryname/yourmatcap.png`.

### Linux Instructions

To build and run for Linux, simply run:

```
git lfs pull
icompile --opt --run
```

To run the sampling mechanism, run:

```
icompile --run --sample <N> <Pattern> <SDF> <outdir>
```

Where `<N>` is the number of points to sample, the argument to `<Pattern>` is the name of the
sampler shader, `<SDF>` is the name of the SDF shader, and `<outdir>` is the directory that
receives the samples as `<outdir>/<Pattern>/<SDF>.bin`.

### Headless Linux (EGL)

On a machine without a display (a GPU server or cluster node), build G3D with its EGL
libraries (`./buildg3d lib` builds `G3D-gfx-egl` and `G3D-app-egl` on Linux) and then build the
explorer against them. On GCC 13 or newer, G3D's bundled TBB 2020 does not compile
(`-Wchanges-meaning` is an error); build it with clang by passing `compiler=clang` to the
`make` call in `buildg3d`'s `tbbTarget`.

```
icompile --egl --opt
cd build
./sdf-explorer-egl --sample 1000000 surface Teapot ../samples
```

iCompile keeps the compiler options of the previous build in
`.ice-tmp/sdf-explorer/.icompile-cache`, so delete that file when switching between
`icompile --egl` and a plain `icompile`; otherwise the second build compiles with the first
one's `-DGLEW_EGL` setting and fails to link.

The EGL build renders into an offscreen buffer on the GPU through `EGL_PLATFORM_DEVICE_EXT`
and needs no X server. It only samples; it has no interactive window. `G3D10DATA` must point
at the G3D data directories, as in `set_g3d_env.sh`.

To sample every SDF with the patterns used for the released dataset and save `.npz` files:

```
cd sdfdes
python sample_all.py --out ../samples
```

### Loading the Binaries

If you want to load the custom generated binary files from the sampler, you can use the Python 
package in `sdfdes` (see the README inside the `sdfdes` folder for more details).

## Extending the Dataset

Extending our dataset mostly amounts to adding files into appropriate subdirectories in `data-files`.
We welcome any pull requests to add any shaders, sampling schemes, or matcaps, but please 
be respectful and adhere to GitHub's 
[community guidelines](https://docs.github.com/en/free-pro-team@latest/github/site-policy/github-community-guidelines).

### Signed Distance Functions

To add a new SDF shader, simply add a new GLSL file under `data-files/sdf`. The GLSL function 
will need to implement a single function which takes in a `vec3` as input and spits out a `float`. 
Here is a simple example which implements a sphere SDF:

```C++
float sdf(vec3 p)
{
    return length(p)-0.5;
}
```

### Sampling Scheme

To add a new sampling scheme, you can similarly add a new GLSL file under `data-files/sampler`.
Sampling schemes are implemented with a function `sdf_sampler`, which returns `vec4` where the
first 3 dimensions correspond to position, and the last dimension is the distance.

### Matcaps

Matcaps are 2D texture files, preferably in PNG format. To add new matcaps, simply add them to 
`data-files/matcap`. They should be named like: `_Color.ext` for textures, `_Displacement.ext` for 
displacement, and `_Normal.jpg` for normal maps. 

### Textures

We also support texture maps, displacement maps, and normal maps. You can place them in `data-files/texture`

### Other useful things

See `data-files/shader` for the core shaders that are responsible for rendering our SDFs. 
Most of the interesting stuff is in `data-files/shader/App_visualize.pix`. You can run our
explorer, edit `App_visualize.pix`, and press `F5` to reload the shader. Most custom
rendering applications can be done by modifying `App_visualize.pix`. 

## Citation

To cite our dataset, use the following bibtex:

```
@article{Takikawa2022SDF,
  author =       {Towaki Takikawa and Andrew Glassner and Morgan McGuire}, 
  title =        {A Dataset and Explorer for 3D Signed Distance Functions},
  year =         2022,
  month =        {April},
  day =          27,
  journal =      {Journal of Computer Graphics Techniques (JCGT)},
  volume =       11,
  number =       2,
  pages =        {1--29},
  url =          {http://jcgt.org/published/0011/02/01/},
  issn =         {2331-7418}
}          
```


## License

```
The MIT License (MIT)

Copyright (c) 2021, NVIDIA CORPORATION.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```


