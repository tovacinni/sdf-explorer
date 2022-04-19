/*
Copyright 2013 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ldl3zN
Archive Link: https://web.archive.org/web/20191113083048/https://www.shadertoy.com/view/ldl3zN
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef upright_glsl
#define upright_glsl

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

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

float udRoundBox( vec3 p, vec3 b, vec3 r )
{
  return length(max(abs(p)-b,0.0))-r.x;
}

float opRepLim( in float p, in float s, in float mi, in float ma )
{
    return p-s*clamp(round(p/s),mi,ma);
}

float obj1( in vec3 p )
{
    vec3 q = vec3( opRepLim(p.x+0.1,0.2,-22.0,23.0), p.yz-0.1 );
	return udRoundBox( q, vec3(0.091,0.075,0.6)-0.005, vec3(0.01) );
}

float obj2( in vec3 p, in float d )
{
    vec3 q = vec3( opRepLim(p.x,0.2,-21.0,23.0), p.y-0.185, p.z - 0.3 );
	float k = mod( round( p.x/0.2 ), 7.0 );

	if( k==2.0 || k==6.0 ) return d;

	return udRoundBox( q, vec3(0.06,0.075,0.4)-0.01, vec3(0.01,0.01,0.01) );
}

float obj3( in vec3 p )
{
	float d1 = udRoundBox( p - vec3(0.0, 0.0,1.7), vec3(5.4,0.6,1.0), vec3(0.05) );
	float d2 = udRoundBox( p - vec3(0.0,-0.3,0.1), vec3(5.4,0.3,0.6), vec3(0.05) );
	float d3 = udRoundBox( p - vec3(0.0,-1.0,2.5), vec3(5.4,3.0,1.0), vec3(0.05) );

	float d4 = sdCylinder( vec3(abs(p.x),p.y,p.z) - vec3(5.25,-2.2,-0.35), vec2(0.1,1.85) );
    d4 -= 0.03*smoothstep(-0.7,0.7,sin(18.0*p.y)) + 0.017*p.y + 0.025;

	float d5 = udRoundBox( vec3(abs(p.x),p.y,p.z) - vec3(5.05,0.0,0.3), vec3(0.35,0.2,0.8), vec3(0.05) );
	
	return min( min( min( min( d1, d2 ), d3 ), d4 ), d5 );
}

float obj4( in vec3 p )
{
    return 3.75+p.y;
}

float obj5( in vec3 p )
{
    return min( 3.5-p.z, p.x+6.5 );
}

float obj6( in vec3 p )
{
	vec3 q = p - vec3(0.0,1.3,1.1);
	float x = abs(q.x);
	q.z += 0.15*4.0*x*(1.0-x);
	q.yz = mat2(0.9,-0.43,0.43,0.9)*q.yz;
    return 0.5*udRoundBox( q, vec3(1.0,0.7,0.0), vec3(0.01) );
}


float obj8( in vec3 p )
{
	vec3 q = p - vec3(-0.5,-1.8,-2.0);
	
	q.xz = mat2( 0.9,0.44,-0.44,0.9)*q.xz;
	
	float y = 0.5 + 0.5*sin(8.0*q.x)*sin(8.0*q.z);
	y = 0.1*pow(y,3.0) * smoothstep( 0.1,0.4,q.y );
    float d = udRoundBox( q, vec3(1.5,0.25,0.6), vec3(0.3) );
	d += y;
	
	vec3 s = vec3( abs(q.x), q.y, abs(q.z) );
	float d2 = sdCylinder( s - vec3(1.4,-1.2,0.6), vec2(0.15,1.05) );
	return min( d, d2 );
}


float obj7( in vec3 p )
{
	vec3 q = p - vec3(1.0,-3.6,1.2);
	vec3 r = vec3( mod( q.x-0.25, 0.5 ) - 0.25, q.yz );
    return max( 0.5*udRoundBox( r, vec3(0.05,0.0,0.38), vec3(0.08) ), sdBox( q, vec3(0.75,1.0,1.0) ) );
}

vec2 upright_map( in vec3 p )
{
	// white keys
    vec2 res = vec2( obj1( p ), 0.0 );

	// black keys
    vec2 ob2 = vec2( obj2( p, res.x ), 1.0 );
	if( ob2.x<res.x ) res=ob2;

    // piano body
    vec2 ob3 = vec2( obj3( p ), 2.0 );
    if( ob3.x<res.x ) res=ob3;

	// paper
    vec2 ob6 = vec2( obj6( p ), 5.0 );
    if( ob6.x<res.x ) res=ob6;
	
	// pedals
    vec2 ob7 = vec2( obj7( p ), 6.0 );
    if( ob7.x<res.x ) res=ob7;

	// bench
    vec2 ob8 = vec2( obj8( p ), 7.0 );
    if( ob8.x<res.x ) res=ob8;

	return res;
}

float sdf(vec3 p)
{
	p *= RotMat(vec3(0.,1.,0.), pi);
	const float scale = 0.14;
	p *= 1. / scale;
	return upright_map(p).x * scale;
}

#endif
