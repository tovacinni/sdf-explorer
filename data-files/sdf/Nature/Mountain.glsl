/*
Copyright 2020 Morgan McGuire @CasualEffects
The MIT License
Link: N/A
*/

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

#ifndef mountain_glsl
#define mountain_glsl

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// from G3D noise.glsl
float mountain_hash(vec2 p) { return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float mountain_noise1(vec2 x) {
    vec2 i = floor(x);
    vec2 f = frac(x);

    // Four corners in 2D of a tile
    float a = mountain_hash(i);
    float b = mountain_hash(i + vec2(1.0, 0.0));
    float c = mountain_hash(i + vec2(0.0, 1.0));
    float d = mountain_hash(i + vec2(1.0, 1.0));

    // Simple 2D lerp using smoothstep envelope between the values.
    // return vec3(lerp(lerp(a, b, smoothstep(0.0, 1.0, f.x)),
    //          lerp(c, d, smoothstep(0.0, 1.0, f.x)),
    //          smoothstep(0.0, 1.0, f.y)));

    // Same code, with the clamps in smoothstep and common subexpressions
    // optimized away.
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


float mountain_noise(vec2 x, const int numOctaves) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100, 50);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < numOctaves; ++i) {
        v += a * mountain_noise1(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}


float sdf(vec3 p) {
    // Measure distance rom a conservative bounding box for speed when far away
    float dBigBox = sdBox(p, vec3(0.75));
    if (dBigBox > 0.25) {
        return dBigBox;
    }

    // Intersect these two shapes
    float dBox = sdBox(p, vec3(0.5));

    // Measure *vertical* distance, and then assume that is close to the 3D distance.
    // This process is not at all metric, so we make it conservative
    // by significantly scaling down its estimates of distance. This is worst for 
    // steep cliffs.
    vec2 offset = p.xz - vec2(0.05, 0.07);
    float d = dot(offset, offset);
    d = 0.8 * pow(d, 0.36987 + 0.00415 / d);
    float terrainVertical = (p.y + d - mountain_noise(p.xz * 2.0 + vec2(0.6, 1.6), 9) + 0.3);

    float lakeVertical = p.y + 0.48;

    const float conservativeFactor = 0.3;
    float terrain = min(terrainVertical, lakeVertical) * conservativeFactor;
    return max(dBox, terrain);
}

#endif
