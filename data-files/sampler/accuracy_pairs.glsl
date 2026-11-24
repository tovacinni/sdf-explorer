/******************************************************************************
 * The MIT License (MIT)
 * Copyright (c) 2021, NVIDIA CORPORATION.
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#ifndef accuracy_pairs_glsl
#define accuracy_pairs_glsl

// Accuracy analysis, not a training distribution. Pairs of points in the
// [-2, 2]^3 box with the raw sdf() (not sdf_bounded), so the field is
// measured outside the shape's cube too. Sample 2k is a uniform point and
// sample 2k+1 is that point moved 0.01 in a uniform direction; a distance
// field changes by at most 0.01 between them.
vec4 sdf_sampler(vec2 uv, int size) {
    int idx = int(uv.y) * size + int(uv.x);
    int pairId = idx / 2;
    uint draw = 0u;
    vec2 key = vec2(float(pairId % 4096), float(pairId / 4096));
    vec3 p = nextUniform(key, draw) * 4.0 - 2.0;
    vec3 dir = normalize(nextGaussian(key, draw));
    if ((idx % 2) == 1) {
        p += 0.01 * dir;
    }
    return vec4(p, sdf(p));
}

#endif
