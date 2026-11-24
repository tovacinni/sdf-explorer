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

#ifndef accuracy_ball_glsl
#define accuracy_ball_glsl

// Accuracy analysis, not a training distribution: a test for overestimation
// that needs no reference surface. p is uniform in [-2, 2]^3 and q is uniform
// in the ball of radius 0.95 |sdf(p)| around p. An exact or conservative SDF
// has no surface inside that ball, so sdf(q) has the sign of sdf(p). The
// stored distance is sign(sdf(p)) * sdf(q); a negative value proves that
// sdf(p) is larger than the distance from p to the surface.
vec4 sdf_sampler(vec2 uv, int size) {
    uint draw = 0u;
    vec3 p = nextUniform(uv, draw) * 4.0 - 2.0;
    float sp = sdf(p);
    vec3 dir = normalize(nextGaussian(uv, draw));
    float radius = 0.95 * abs(sp) * pow(nextUniform(uv, draw).x, 1.0 / 3.0);
    return vec4(p, sign(sp) * sdf(p + dir * radius));
}

#endif
