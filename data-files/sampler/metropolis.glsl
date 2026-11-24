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

#ifndef metropolis_glsl
#define metropolis_glsl

const int NUM_ITER = 50;

// Metropolis-Hastings chain with target density proportional to 1/|s(p)| on
// the [-1, 1] cube, which concentrates samples near the zero level set. The
// chain starts at a uniform point in the cube; proposals are Gaussian steps
// (sigma 0.2); a step is accepted with probability min(1, |s(p)| / |s(next)|),
// and a step leaving the cube is rejected.
vec4 sdf_sampler(vec2 uv, int size) {
    uint draw = 0u;
    vec3 p = nextUniform(uv, draw) * 2.0 - 1.0;
    float pDistance = abs(sdf_bounded(p));
    for (int i = 0; i < NUM_ITER; ++i) {
        vec3 next = p + nextGaussian(uv, draw) * 0.2;
        float u = nextUniform(uv, draw).x;
        if (insideSampleCube(next)) {
            float nextDistance = abs(sdf_bounded(next));
            if (u * nextDistance < pDistance) {
                p = next;
                pDistance = nextDistance;
            }
        }
    }
    return vec4(p, sdf_bounded(p));
}

#endif
