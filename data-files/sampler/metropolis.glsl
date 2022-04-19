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

vec4 sdf_sampler(vec2 uv, int size) {
    vec3 p = vec3(rand(uv/size).xyz) * 2.0 - 1.0;
    vec3 random_idx = rand(uv/size).xyz;
    for (int i=0; i<NUM_ITER; ++i) {
        // Next step
        vec3 delta = gaussian(random_idx.xy).xyz * 0.2;
        vec3 next = p + delta;

        // Calculate acceptance probability
        float ratio = abs(sdf_bounded(next)) / abs(sdf_bounded(p));

        if (min(1, ratio) < 1.0) {
            p = next;
        }
        random_idx = rand(random_idx.xy).xyz;
    }
    return vec4(p, sdf_bounded(p));
}

#endif

