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

#ifndef metropolis_curvature_glsl
#define metropolis_curvature_glsl

const int NUM_ITER = 25;

const float NaN = uintBitsToFloat(0x7fc00000);

// Traces up to 100 rays in uniform directions from rayOrigin and returns the
// first hit inside the [-1, 1] cube.
bool raystab(vec3 rayOrigin, vec2 uv, inout uint draw, out vec3 hitpoint) {
    vec3 temp;
    float t;
    for (int i = 0; i < 100; ++i) {
        vec3 rayDirection = normalize(nextGaussian(uv, draw));
        if (intersectSDF(rayOrigin, rayDirection, 20.0, t, temp) && insideSampleCube(temp)) {
            hitpoint = temp;
            return true;
        }
    }
    hitpoint = rayOrigin;
    return false;
}

// Metropolis-Hastings chain with target density proportional to the absolute
// mean curvature on the zero level set inside the [-1, 1] cube. Step 0 stabs a
// ray from a uniform point in the cube; a sample whose first stab misses is all
// NaN. Each of the NUM_ITER later steps proposes the hit of a ray from a new
// uniform origin and accepts it with probability
// min(1, |curv(next)| / |curv(p)|). The accepted point is then moved by
// N(0, 0.01^2) per axis. raystab and sdf_curv each appear once so the compiler
// inlines one copy of the SDF per call; large SDFs exceed the GLSL compiler's
// limits otherwise.
vec4 sdf_sampler(vec2 uv, int size) {
    uint draw = 0u;
    vec3 p = vec3(NaN, NaN, NaN);
    float pCurvature = 0.0;

    for (int i = 0; i <= NUM_ITER; ++i) {
        vec3 rayOrigin = nextUniform(uv, draw) * 2.0 - 1.0;
        vec3 next;
        if (raystab(rayOrigin, uv, draw, next)) {
            float nextCurvature = abs(sdf_curv(next));
            float u = nextUniform(uv, draw).x;
            if ((i == 0) || (u * pCurvature < nextCurvature)) {
                p = next;
                pCurvature = nextCurvature;
            }
        } else if (i == 0) {
            return vec4(p, sdf(p));
        }
    }
    p += nextGaussian(uv, draw) * 0.01;
    return vec4(p, sdf_bounded(p));
}

#endif
