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

#ifndef trace_glsl
#define trace_glsl

const float NaN = uintBitsToFloat(0x7fc00000);

vec4 sdf_sampler(vec2 uv, int size) {
    vec3 rayOrigin = vec3(rand(uv/size).xyz) * 2.0 - 1.0;
    vec3 p;
    float t;
    vec2 random_idx = uv/size;
    for (int i=0; i<100; ++i){
        vec3 n = gaussian(random_idx).xyz;
        vec3 rayDirection = (1.0 / length(n)) * n;
        if (intersectSDF(rayOrigin, rayDirection, 20.0, t, p)) {
            return vec4(p, sdf_bounded(p));
        }
        random_idx = rand(random_idx).xy;
    }

    p = vec3(NaN, NaN, NaN); 
    return vec4(p, sdf(p));
}

#endif

