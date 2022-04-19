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

#ifndef rand_glsl
#define rand_glsl

const int NUM_ITER = 25;

const float NaN = uintBitsToFloat(0x7fc00000);

bool raystab(vec3 rayOrigin, vec3 random_idx, out vec3 hitpoint) {
    vec3 temp;
    vec2 random_uv = random_idx.xy;
    float t;
    // Raystab
    for (int i=0; i<100; ++i){ 
        vec3 n = gaussian(random_uv).xyz;
        vec3 rayDirection = (1.0 / length(n)) * n; // Sphere point select
        if (intersectSDF(rayOrigin, rayDirection, 20.0, t, temp)) {
            hitpoint = temp;
            return true; // If found, return the hitpoint
        }
        random_uv = rand(random_uv).xy; // Reroll
    }
    hitpoint = rayOrigin;
    return false; // If not found, return input
}

vec4 sdf_sampler(vec2 uv, int size) {

    // Initial point
    vec3 p = vec3(rand(uv/size).xyz) * 2.0 - 1.0;
    vec3 random_idx = rand(uv/size).xyz; 
    if (!raystab(p, random_idx, p)) {
        p = vec3(NaN, NaN, NaN); 
        return vec4(p, sdf(p));
    }
    random_idx = rand(random_idx.xy).xyz;

    // Start metropolis search
    for (int i=0; i<NUM_ITER; ++i) {

        // Find next candidate point by intersecting
        vec3 rayOrigin = random_idx.xyz; // Start from random location
        vec3 next;
        if (!raystab(rayOrigin, random_idx, next)) {
            random_idx = rand(random_idx.xy).xyz;
            continue; // No hit; just go to next metropolis
        }

        // Calculate acceptance probability of new intersection
        //float ratio = ( abs( sdf( next ) ) + abs( curv( p    ) ) ) /
        //              ( abs( sdf( p    ) ) + abs( curv( next ) ) );
        float ratio = abs(sdf_curv(p)) / abs(sdf_curv(next));

        if (min(1, ratio) < 1.0) {
            p = next;
        }
        random_idx = rand(random_idx.xy).xyz;
    }
    p += gaussian(random_idx.xy).xyz * 0.01;
    return vec4(p, sdf_bounded(p));
}

#endif

