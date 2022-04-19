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

#ifndef App_raycast_glsl
#define App_raycast_glsl

#include <g3dmath.glsl>
#include ACTIVE_SHADER

uniform mat4x3 modelMatrix;
uniform float modelRadius;


#ifdef SPATIAL_SAMPLING
uniform vec3 bbCoords;
uniform float bbExtent;
#else
const vec3 bbCoords = vec3(0.0, 0.0, 0.0);
const float bbExtent = 1.0 / 1.0; // 1 / res
#endif

const vec3 bbOffset = vec3((1.0 / bbExtent) - 1.0) - (bbCoords * 2.0);

#if RENDER_DISPLACEMENT
uniform sampler2D tdisplacement;

Vector3 sdf_displacement(Point3 p) {
    Point3 vP = p * 0.5 + 0.5;
    Vector3 xyz;
    xyz.x = texture( tdisplacement, vP.zy ).r;
    xyz.y = texture( tdisplacement, vP.xz ).r;
    xyz.z = texture( tdisplacement, vP.xy ).r;
    return normalize(xyz) * 0.015;
}
#endif

// A point this close to the surface is considered to be on the surface.
// Larger numbers lead to faster convergence but "blur" out the shape
const float minimumDistanceToSurface = 0.00003;

// Larger is slower but more accurate and fills holes
const int RAY_MARCH_ITERATIONS =
#if FAST
    150;
#else
    400;
#endif

float sdf_bb(Point3 p) {
    vec3 d = abs(p) - vec3(1.0);
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdf_bounded(Point3 p) {
    float scaled_sdf = sdf((p - bbOffset) * bbExtent) * (1./bbExtent);
    return max(scaled_sdf, sdf_bb(p));
}

float distanceToSurface(Point3 p) {
#if RENDER_DISPLACEMENT    
    p += sdf_displacement(p);
#endif 
    p = (modelMatrix * vec4(p, 1.0)).xyz;
    return sdf(p) - modelRadius;
    // Experimental bounded sampling code
    //return sdf_bounded(p);
}

bool intersectSDF(Point3 rayOrigin, Vector3 rayDirection, float maxDist, inout float t, inout Point3 X) {
    
    t = 0.0;
    int s = 1;
    float side = sign(distanceToSurface(rayOrigin));

    // March along the ray, detecting when we are very close to the surface
    for (int i = 0; (i < RAY_MARCH_ITERATIONS) && (t < maxDist); ++i) {
        X = rayOrigin + rayDirection * t;

        float d;
        
        d = side * distanceToSurface(X) * 0.99;

        if (d < minimumDistanceToSurface) { 
            return true;
        }

        // Advance along the ray by the worst-case distance to the
        // surface in any direction
        t += d + minimumDistanceToSurface;
    }

    return false;
}

#endif
