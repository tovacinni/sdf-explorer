/*
Copyright 2017 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ldScDh
Archive Link: https://web.archive.org/web/20191106150158/https://www.shadertoy.com/view/ldScDh
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef temple_glsl
#define temple_glsl

// Noise functions
// These are taken from https://www.shadertoy.com/view/ldSSzV
float hash11(float p) {
    return fract(sin(p * 727.1)*435.545);
}
float hash12(vec2 p) {
    float h = dot(p,vec2(127.1,311.7)); 
    return fract(sin(h)*437.545);
}
vec3 hash31(float p) {
    vec3 h = vec3(127.231,491.7,718.423) * p;   
    return fract(sin(h)*435.543);
}
// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);  
    vec3 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
    float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
    float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
    b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
    d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
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
float fbm3_high(vec3 p, float a, float f) {
    float ret = 0.0;    
    float amp = 1.0;
    float frq = 1.0;
    for(int i = 0; i < 5; i++) {
        float n = pow(noise_3(p * frq),2.0);
        ret += n * amp;
        frq *= f;
        amp *= a * (pow(n,0.2));
    }
    return ret;
}

float hash1( vec2 p )
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus( in vec2 p, in vec2 b, in float r ) 
{
    vec2 q = abs(p);
    float h = clamp( (-2.0*ndot(q,b) + ndot(b,b) )/dot(b,b), -1.0, 1.0 );
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    d *= sign( q.x*b.y + q.y*b.x - b.x*b.y );
    return d - r;
}

float utemple_sdBox( in vec3 p, in vec3 b )
{
    return length( max(abs(p)-b,0.0 ) );
}


float temple_sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float temple_sdBox( float p, float b )
{
  return abs(p) - b;
}

vec2 opRepLim( in vec2 p, in float s, in vec2 lim )
{
    return p-s*clamp(round(p/s),-lim,lim);
}

vec2 opRepLim( in vec2 p, in float s, in vec2 limmin, in vec2 limmax )
{
    return p-s*clamp(round(p/s),-limmin,limmax);
}

vec3 temple( in vec3 p )
{
    vec3 op = p;    
    vec3 res = vec3(-1.0,-1.0,0.5);

    p.y += 2.0;

    // bounding box
    float bbox = utemple_sdBox(p,vec3(15.0,12.0,15.0)*1.5 );
    if( bbox>5.0 ) return vec3(bbox+1.0,-1.0,0.5);
    vec3 q = p; q.xz = opRepLim( q.xz, 4.0, vec2(4.0,2.0) );
    
    // columns
    vec2 id = floor((p.xz+2.0)/4.0);

    float d = length(q.xz) - 0.9 + 0.05*p.y;
    d = max(d,p.y-6.0);
    d = max(d,-p.y-5.0);
    d -= 0.05*pow(0.5+0.5*sin(atan(q.x,q.z)*16.0),2.0);
    d -= 0.15*pow(0.5+0.5*sin(q.y*3.0+0.6),0.12) - 0.15;
    res.z = hash1( id + 11.0*floor(0.25 + (q.y*3.0+0.6)/6.2831) );
    d *= 0.85;
    
    {
    vec3 qq = vec3(q.x,abs(q.y-0.3)-5.5, q.z );
    d = min( d, temple_sdBox( qq,vec3(1.4,0.2,1.4)+sign(q.y-0.3)*vec3(0.1,0.05,0.1))-0.1 ); // base
    }    

    d = max( d, -temple_sdBox(p,vec3(14.0,10.0,6.0)) ); // clip in

    // floor
    float ra = 0.15 * hash1(id+vec2(1.0,3.0));
    q = p; q.xz = opRepLim( q.xz, 4.0, vec2(4.0,3.0) );
    float b = temple_sdBox( q-vec3(0.0,-6.0+0.1-ra,0.0), vec3(2.0,0.5,2.0)-0.15-ra )-0.15;
    b *= 0.5;
    if( b<d ) { d = b; res.z = hash1(id); }
    
    p.xz -= 2.0;
    id = floor((p.xz+2.0)/4.0);
    ra = 0.15 * hash1(id+vec2(1.0,3.0)+23.1);
    q = p; q.xz = opRepLim( q.xz, 4.0, vec2(5.0,4.0), vec2(5.0,3.0) );
    b = temple_sdBox( q-vec3(0.0,-7.0-ra,0.0), vec3(2.0,0.6,2.0)-0.15-ra )-0.15;
    b *= 0.8;
    if( b<d ) { d = b; res.z = hash1( id + 13.5 ); }
    p.xz += 2.0;
    
    id = floor((p.xz+2.0)/4.0);
    ra = 0.15 * hash1(id+vec2(1.0,3.0)+37.7);
    q = p; q.xz = opRepLim( q.xz, 4.0, vec2(5.0,4.0) );
    b = temple_sdBox( q-vec3(0.0,-8.0-ra-1.0,0.0), vec3(2.0,0.6+1.0,2.0)-0.15-ra )-0.15;
    b *= 0.5;
    if( b<d ) { d = b; res.z = hash1( id*7.0 + 31.1 ); }

    
    // roof
    q = vec3( mod(p.x+2.0,4.0)-2.0, p.y, mod(p.z+0.0,4.0)-2.0 );
    b = temple_sdBox( q-vec3(0.0,7.0,0.0), vec3(1.95,1.0,1.95)-0.15 )-0.15;
    b = max( b, temple_sdBox(p-vec3(0.0,7.0,0.0),vec3(18.0,1.0,10.0)) );
    if( b<d ) { d = b; res.z = hash1( floor((p.xz+vec2(2.0,0.0))/4.0) + 31.1 ); }
    
    q = vec3( mod(p.x+0.5,1.0)-0.5, p.y, mod(p.z+0.5,1.0)-0.5 );
    b = temple_sdBox( q-vec3(0.0,8.0,0.0), vec3(0.45,0.5,0.45)-0.02 )-0.02;
    b = max( b, temple_sdBox(p-vec3(0.0,8.0,0.0),vec3(19.0,0.2,11.0)) );
    //q = p+vec3(0.0,0.0,-0.5); q.xz = opRepLim( q.xz, 1.0, vec2(19.0,10.0) );
    //b = temple_sdBox( q-vec3(0.0,8.0,0.0), vec3(0.45,0.2,0.45)-0.02 )-0.02;
    if( b<d ) { d = b; res.z = hash1( floor((p.xz+0.5)/1.0) + 7.8 ); }

    
    
    b = sdRhombus( p.yz-vec2(8.2,0.0), vec2(3.0,11.0), 0.05 ) ;
    q = vec3( mod(p.x+1.0,2.0)-1.0, p.y, mod(p.z+1.0,2.0)-1.0 );
    b = max( b, -temple_sdBox( vec3( abs(p.x)-20.0,p.y,q.z)-vec3(0.0,8.0,0.0), vec3(2.0,5.0,0.1) )-0.02 );
    
    b = max( b, -p.y+8.2 );
    b = max( b, utemple_sdBox(p-vec3(0.0,8.0,0.0),vec3(19.0,12.0,11.0)) );
    float c = sdRhombus( p.yz-vec2(8.3,0.0), vec2(2.25,8.5), 0.05 );
    c = max( c, temple_sdBox(abs(p.x)-19.0,2.0) );
    b = max( b, -c );    
    

    d = min( d, b );

    d = max( d,-temple_sdBox(p-vec3(0.0,9.5,0.0),vec3(15.0,4.0,9.0)) );


    d -= 0.02*smoothstep(0.5,1.0,fbm3_high( p.zxy, 0.4, 2.96 ));
    d -= 0.01*smoothstep(0.4,0.8,fbm3_high( op*3.0, 0.4, 2.96 ));
    //d += 0.005;
    
    res = vec3( d, 1.0, res.z );

    return res;
}

float sdf(vec3 p)
{
    p *= RotMat(vec3(0.,1.,0.), -pi/2.);
    const float scale = 0.04;
    p *= 1. / scale;
    return temple(p).x * scale * 0.7;
}

#endif
