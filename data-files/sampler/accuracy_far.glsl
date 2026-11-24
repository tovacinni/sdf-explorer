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

#ifndef accuracy_far_glsl
#define accuracy_far_glsl

// Accuracy analysis, not a training distribution. Uniform directions at
// radius 10^u, u uniform in [0, 2] (1 to 100 units from the origin), with the
// raw sdf(). The shape lies in the [-1, 1] cube, so the true distance at
// radius r is within sqrt(3) of r.
vec4 sdf_sampler(vec2 uv, int size) {
    uint draw = 0u;
    vec3 dir = normalize(nextGaussian(uv, draw));
    float radius = pow(10.0, 2.0 * nextUniform(uv, draw).x);
    vec3 p = dir * radius;
    return vec4(p, sdf(p));
}

#endif
