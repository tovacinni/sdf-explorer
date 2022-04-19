/*
Copyright 2014 Morgan McGuire @CasualEffects
The 2-Clause BSD License
Link: https://www.shadertoy.com/view/XsXXWS
*/

/******************************************************************************
 This work is a derivative of work by Morgan McGuire used under the FreeBSD License.
 This work is licensed also under FreeBSD by NVIDIA CORPORATION.
 ******************************************************************************/

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

#ifndef mendelbulb_glsl
#define mandelbulb_glsl

#define Color4 vec4
#define Color3 vec3
#define Point3 vec3
#define Vector3 vec3

const float mandelbulb_minimumDistanceToSurface = 0.0003;

// Higher is more complex and fills holes
const int ITERATIONS = 16;

// Different values give different shapes; 8.0 is the "standard" bulb
const float power = 8.0;

// AO = scale surface brightness by this value. 0 = deep valley, 1 = high ridge
float distanceToSurface(Point3 P, out float AO) {
	AO = 1.0;
	
	// Sample distance function for a sphere:
	// return length(P) - 1.0;
	
	// Unit rounded box (http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)
	//return length(max(abs(P) - 1.0, 0.0)) - 0.1;	
	
	// This is a 3D analog of the 2D Mandelbrot set. Altering the mandlebulbExponent
	// affects the shape.
	// See the equation at
	// http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/	
	Point3 Q = P;
	
	// Put the whole shape in a bounding sphere to 
	// speed up distant ray marching. This is necessary
	// to ensure that we don't expend all ray march iterations
	// before even approaching the surface
	{
		const float externalBoundingRadius = 1.2;
		float r = length(P) - externalBoundingRadius;
		// If we're more than 1 unit away from the
		// surface, return that distance
		if (r > 1.0) { return r; }
	}

	// Embed a sphere within the fractal to fill in holes under low iteration counts
	const float internalBoundingRadius = 0.72;

	// Used to smooth discrete iterations into continuous distance field
	// (similar to the trick used for coloring the Mandelbrot set)	
	float derivative = 1.0;
	
	for (int i = 0; i < ITERATIONS; ++i) {
		// Darken as we go deeper
		AO *= 0.725;
		float r = length(Q);
		
		if (r > 2.0) {	
			// The point escaped. Remap AO for more brightness and return
			AO = min((AO + 0.075) * 4.1, 1.0);
			return min(length(P) - internalBoundingRadius, 0.5 * log(r) * r / derivative);
		} else {		
			// Convert to polar coordinates and then rotate by the power
			float theta = acos(Q.z / r) * power;
			float phi   = atan(Q.y, Q.x) * power;			
			
			// Update the derivative
			derivative = pow(r, power - 1.0) * power * derivative + 1.0;
			
			// Convert back to Cartesian coordinates and 
			// offset by the original point (which we're orbiting)
			float sinTheta = sin(theta);
			
			Q = Vector3(sinTheta * cos(phi),
					    sinTheta * sin(phi),
					    cos(theta)) * pow(r, power) + P;
		}			
	}
	
	// Never escaped, so either already in the set...or a complete miss
	return mandelbulb_minimumDistanceToSurface;
}


float sdf(vec3 p) {
	const float scale = 0.6;
	p *= 1./scale;
	float ignore;
	return distanceToSurface(p, ignore) * scale;
}

#endif
