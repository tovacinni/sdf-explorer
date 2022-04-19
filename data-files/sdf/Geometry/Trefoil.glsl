/*
Copyright 2018 @dr2
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
Link: https://www.shadertoy.com/view/ldtczX
*/

/******************************************************************************
 This work is a derivative of work by dr2 used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef trefoil_glsl
#define trefoil_glsl

#define DMINQ(id) if (d < dMin) { dMin = d; }

mat3 RotMat(vec3 axis, float angle)
{
    // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc*axis.x*axis.x+c,         oc*axis.x*axis.y-axis.z*s,  oc*axis.z*axis.x+axis.y*s, 
                oc*axis.x*axis.y+axis.z*s,  oc*axis.y*axis.y+c,         oc*axis.y*axis.z-axis.x*s, 
                oc*axis.z*axis.x-axis.y*s,  oc*axis.y*axis.z+axis.x*s,  oc*axis.z*axis.z+c);
}

float dstFar = 100;

float trefoil_PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

vec2 trefoil_Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

float ObjDf (vec3 p, float r)
{
  vec3 q;
  float dMin, d, a;
  dMin = dstFar;
  q = p;
  a = atan (q.z, q.x);
  q.xz = vec2 (length (q.xz) - r, q.y);
  q.xz = trefoil_Rot2D (q.xz, 1.5 * a);
  q.xz = trefoil_Rot2D (q.xz, - pi * (floor (atan (q.z, q.x) / pi + 0.5)));
  q.x -= 1.;
  //q.y = a - aa;
  d = length (trefoil_PrBox2Df (q.xz, vec2 (0.2))) - 0.05;
  DMINQ (1);
  return 0.4 * dMin;
}

float sdf(vec3 p)
{
	p *= RotMat(vec3(1.,0.,0.), pi/2.);
	const float scale = 0.18;
	p *= 1. / scale;
	return ObjDf(p, 3.5) * scale;
}

#endif
