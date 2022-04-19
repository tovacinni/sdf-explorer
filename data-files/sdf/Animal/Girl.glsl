/*
Copyright 2020 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/WsSBzh
Archive Link: https://web.archive.org/web/20201128010927/https://www.shadertoy.com/view/WsSBzh
 */

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef girl_glsl
#define girl_glsl

#define TIME g3d_SceneTime

// Created by inigo quilez - iq/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Source code of the mathematical painting "Selfie Girl".
// Making-of video on Youtube:
//
// https://www.youtube.com/watch?v=8--5LwHRhjk

// This in an evolution of my Hoody "4 kilobytes executable
// graphics" entry for the Revision 2020 demoparty. I
// replaced the background and added some animation. This
// version of the shader is also not obfuscated nor
// minimized, since I want it to be easy to read. In fact
// this time I added plenty of comments in the code where I
// talk about how each element in the drawing is made.

// This "Image" tab in particular renders girl through
// raymarching and then performs the final composition with
// the background grabbed from "Buffer B" (open the rest of
// the tabs to see explanations of what each one does).
// There's no TAA in this pass because I didn't want to
// compute velocity vectors for the animation, so things
// alias a bit (feel free to change the AA define below to
// 2 if you have a fast GPU)


// http://iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    k *= 1.4;
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*h/(6.0*k*k);
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smin3( float a, float b, float k )
{
    k *= 1.4;
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*h/(6.0*k*k);
}

float sclamp(in float x, in float a, in float b )
{
    float k = 0.1;
    return smax(smin(x,b,k),a,k);
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opRepLim( in float p, in float s, in float lima, in float limb )
{
    return p-s*clamp(round(p/s),lima,limb);
}


float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
float ndot(vec2 a, vec2 b ) { return a.x*b.x-a.y*b.y; }
float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }


// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus( in vec3 p, in float ra, in float rb )
{
    return length( vec2(length(p.xz)-ra,p.y) )-rb;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
    p.x = abs(p.x);
    float k = (sc.y*p.x>sc.x*p.z) ? dot(p.xz,sc) : length(p.xz);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( in vec3 p, in float r )
{
    return length(p)-r;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdEllipsoid( in vec3 p, in vec3 r )
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( in vec3 p, in vec3 b )
{
    vec3 d = abs(p) - b;
    return min( max(max(d.x,d.y),d.z),0.0) + length(max(d,0.0));
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdArc( in vec2 p, in vec2 scb, in float ra )
{
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p.xy,scb) : length(p.xy);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k );
}

#if 1
// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
// { dist, t, y (above the plane of the curve, x (away from curve in the plane of the curve))
vec4 sdBezier( vec3 p, vec3 va, vec3 vb, vec3 vc )
{
  vec3 w = normalize( cross( vc-vb, va-vb ) );
  vec3 u = normalize( vc-vb );
  vec3 v =          ( cross( w, u ) );
  //----
  vec2 m = vec2( dot(va-vb,u), dot(va-vb,v) );
  vec2 n = vec2( dot(vc-vb,u), dot(vc-vb,v) );
  vec3 q = vec3( dot( p-vb,u), dot( p-vb,v), dot(p-vb,w) );
  //----
  float mn = det(m,n);
  float mq = det(m,q.xy);
  float nq = det(n,q.xy);
  //----
  vec2  g = (nq+mq+mn)*n + (nq+mq-mn)*m;
  float f = (nq-mq+mn)*(nq-mq+mn) + 4.0*mq*nq;
  vec2  z = 0.5*f*vec2(-g.y,g.x)/dot(g,g);
//float t = clamp(0.5+0.5*(det(z,m+n)+mq+nq)/mn, 0.0 ,1.0 );
  float t = clamp(0.5+0.5*(det(z-q.xy,m+n))/mn, 0.0 ,1.0 );
  vec2 cp = m*(1.0-t)*(1.0-t) + n*t*t - q.xy;
  //----
  float d2 = dot(cp,cp);
  return vec4(sqrt(d2+q.z*q.z), t, q.z, -sign(f)*sqrt(d2) );
}
#else
float det( vec3 a, vec3 b, in vec3 v ) { return dot(v,cross(a,b)); }

// my adaptation to 3d of http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
// { dist, t, y (above the plane of the curve, x (away from curve in the plane of the curve))
vec4 sdBezier( vec3 p, vec3 b0, vec3 b1, vec3 b2 )
{
    b0 -= p;
    b1 -= p;
    b2 -= p;

    vec3  d21 = b2-b1;
    vec3  d10 = b1-b0;
    vec3  d20 = (b2-b0)*0.5;

    vec3  n = normalize(cross(d10,d21));

    float a = det(b0,b2,n);
    float b = det(b1,b0,n);
    float d = det(b2,b1,n);
    vec3  g = b*d21 + d*d10 + a*d20;
    float f = a*a*0.25-b*d;

    vec3  z = cross(b0,n) + f*g/dot(g,g);
    float t = clamp( dot(z,d10-d20)/(a+b+d), 0.0 ,1.0 );
    vec3 q = mix(mix(b0,b1,t), mix(b1,b2,t),t);

    float k = dot(q,n);
    return vec4(length(q),t,-k,-sign(f)*length(q-n*k));
}
#endif

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec2 sdSegment(vec3 p, vec3 a, vec3 b)
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ), h );
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec2 sdSegmentOri(vec2 p, vec2 b)
{
    float h = clamp( dot(p,b)/dot(b,b), 0.0, 1.0 );
    return vec2( length( p - b*h ), h );
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdFakeRoundCone(vec3 p, float b, float r1, float r2)
{
    float h = clamp( p.y/b, 0.0, 1.0 );
    p.y -= b*h;
    return length(p) - mix(r1,r2,h);
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCone( in vec3 p, in vec2 c )
{
  vec2 q = vec2( length(p.xz), p.y );

  vec2 a = q - c*clamp( (q.x*c.x+q.y*c.y)/dot(c,c), 0.0, 1.0 );
  vec2 b = q - c*vec2( clamp( q.x/c.x, 0.0, 1.0 ), 1.0 );

  float s = -sign( c.y );
  vec2 d = min( vec2( dot( a, a ), s*(q.x*c.y-q.y*c.x) ),
                vec2( dot( b, b ), s*(q.y-c.y)  ));
  return -sqrt(d.x)*sign(d.y);
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdRhombus(vec3 p, float la, float lb, float h, float ra)
{
    p = abs(p);
    vec2 b = vec2(la,lb);
    float f = clamp( (ndot(b,b-2.0*p.xz))/dot(b,b), -1.0, 1.0 );
    vec2 q = vec2(length(p.xz-0.5*b*vec2(1.0-f,1.0+f))*sign(p.x*b.y+p.z*b.x-b.x*b.y)-ra, p.y-h);
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
vec4 opElongate( in vec3 p, in vec3 h )
{
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0) );
}
//-----------------------------------------------

// ray-infinite-cylinder intersection
vec2 iCylinderY( in vec3 ro, in vec3 rd, in float rad )
{
    vec3 oc = ro;
    float a = dot( rd.xz, rd.xz );
    float b = dot( oc.xz, rd.xz );
    float c = dot( oc.xz, oc.xz ) - rad*rad;
    float h = b*b - a*c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h,-b+h)/a;
}

// ray-infinite-cone intersection
vec2 iConeY(in vec3 ro, in vec3 rd, in float k )
{
    float a = dot(rd.xz,rd.xz) - k*rd.y*rd.y;
    float b = dot(ro.xz,rd.xz) - k*ro.y*rd.y;
    float c = dot(ro.xz,ro.xz) - k*ro.y*ro.y;

    float h = b*b-a*c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h,-b+h)/a;
}

//-----------------------------------------------

float linearstep(float a, float b, in float x )
{
    return clamp( (x-a)/(b-a), 0.0, 1.0 );
}

vec2 rot( in vec2 p, in float an )
{
    float cc = cos(an);
    float ss = sin(an);
    return mat2(cc,-ss,ss,cc)*p;
}

float expSustainedImpulse( float t, float f, float k )
{
    return smoothstep(0.0,f,t)*1.1 - 0.1*exp2(-k*max(t-f,0.0));
}

//-----------------------------------------------

vec3 hash3( uint n )
{
    // integer hash copied from Hugo Elias
    n = (n << 13U) ^ n;
    n = n * (n * n * 15731U + 789221U) + 1376312589U;
    uvec3 k = n * uvec3(n,n*16807U,n*48271U);
    return vec3( k & uvec3(0x7fffffffU))/float(0x7fffffff);
}

//---------------------------------------

float noise1( sampler3D tex, in vec3 x )
{
    return textureLod(tex,(x+0.5)/32.0,0.0).x;
}
float noise1( sampler2D tex, in vec2 x )
{
    return textureLod(tex,(x+0.5)/64.0,0.0).x;
}
float noise1f( sampler2D tex, in vec2 x )
{
    return texture(tex,(x+0.5)/64.0).x;
}
float fbm1( sampler3D tex, in vec3 x )
{
    float f = 0.0;
    f += 0.5000*noise1(tex,x); x*=2.01;
    f += 0.2500*noise1(tex,x); x*=2.01;
    f += 0.1250*noise1(tex,x); x*=2.01;
    f += 0.0625*noise1(tex,x);
    f = 2.0*f-0.9375;
    return f;
}

float fbm1( sampler2D tex, in vec2 x )
{
    float f = 0.0;
    f += 0.5000*noise1(tex,x); x*=2.01;
    f += 0.2500*noise1(tex,x); x*=2.01;
    f += 0.1250*noise1(tex,x); x*=2.01;
    f += 0.0625*noise1(tex,x);
    f = 2.0*f-0.9375;
    return f;
}
float fbm1f( sampler2D tex, in vec2 x )
{
    float f = 0.0;
    f += 0.5000*noise1f(tex,x); x*=2.01;
    f += 0.2500*noise1f(tex,x); x*=2.01;
    f += 0.1250*noise1f(tex,x); x*=2.01;
    f += 0.0625*noise1f(tex,x);
    f = 2.0*f-0.9375;
    return f;
}
float bnoise( in float x )
{
    float i = floor(x);
    float f = fract(x);
    float s = sign(fract(x/2.0)-0.5);
    float k = 0.5+0.5*sin(i);
    return s*f*(f-1.0)*((16.0*k-4.0)*f*(f-1.0)-1.0);
}

vec3 fbm13( in float x, in float g )
{
    vec3 n = vec3(0.0);
    float s = 1.0;
    for( int i=0; i<6; i++ )
    {
        n += s*vec3(bnoise(x),bnoise(x+13.314),bnoise(x+31.7211));
        s *= g;
        x *= 2.01;
        x += 0.131;
    }
    return n;
}

// this SDF is really 6 braids at once (through domain repetition)
// with three strands each (brute forced)
vec4 sdHair( vec3 p, vec3 pa, vec3 pb, vec3 pc, float an, out vec2 occ_id) 
{
    vec4 b = sdBezier(p, pa,pb,pc );
    vec2 q = rot(b.zw,an);
    
    vec2 id2 = round(q/0.1);
    id2 = clamp(id2,vec2(0),vec2(2,1));
    q -= 0.1*id2;

    float id = 11.0*id2.x + id2.y*13.0;

    q += smoothstep(0.5,0.8,b.y)*0.02*vec2(0.4,1.5)*cos( 23.0*b.y + id*vec2(13,17));

    occ_id.x = clamp(length(q)*8.0-0.2,0.0,1.0);
    vec4 res = vec4(99,q,b.y);
    for( int i=0; i<3; i++ )
    {
        vec2 tmp = q + 0.01*cos( id + 180.0*b.y + vec2(2*i,6-2*i));
        float lt = length(tmp)-0.02;
        if( lt<res.x )
        { 
            occ_id.y = id+float(i); 
            res.x = lt; 
            res.yz = tmp;
        }
    }
    return res;
}

// the SDF for the hoodie and jacket. It's a very distorted
// ellipsoid, torus section, a segment and a sphere.
vec4 sdHoodie( in vec3 pos )
{
    vec3 opos = pos;

    pos.x   += 0.09*sin(3.5*pos.y-0.5)*sin(    pos.z) + 0.015;
    pos.xyz += 0.03*sin(2.0*pos.y)*sin(7.0*pos.zyx);
    
    // hoodie
    vec3 hos = pos-vec3(0.0,-0.33,0.15);
    hos.x -= 0.031*smoothstep(0.0,1.0,opos.y+0.33);
    hos.yz = rot(hos.yz,0.9);
    float d1 = sdEllipsoid(hos,vec3(0.96-pos.y*0.1,1.23,1.5));
    float d2 = 0.95*pos.z-0.312*pos.y-0.9;
    float d = max(opOnion(d1,0.01), d2 );
    
    // shoulders
    vec3 sos = vec3( abs(pos.x), pos.yz );    
    vec2 se = sdSegment(sos, vec3(0.18,-1.6,-0.3), vec3(1.1,-1.9,0.0) );
    d = smin(d,se.x-mix(0.25,0.43,se.y),0.4);
    d = smin(d,sdSphere(sos-vec3(0.3,-2.2,0.4), 0.5 ),0.2);

    // neck
    opos.x -= 0.02*sin(9.0*opos.y);
    vec4 w = opElongate( opos-vec3(0.0,-1.2,0.3), vec3(0.0,0.3,0.0) );
    d = smin(d,
             w.w+sdCappedTorus(vec3(w.xy,-w.z),vec2(0.6,-0.8),0.6,0.02),
             0.1);
    
    // bumps
    d += 0.004*sin(pos.x*90.0)*sin(pos.y*90.0)*sin(pos.z*90.0);
    d -= 0.002*sin(pos.x*300.0);
    d -= 0.02*(1.0-smoothstep(0.0,0.04,abs(opOnion(pos.x,1.1))));
    
    // border
    d = min(d,length(vec2(d1,d2))-0.015);
    
    return vec4(d,pos);
}

// moves the head (and hair and hoodie). This could be done more
// efficiently (with a single matrix or quaternion), but this code
// was optimized for editing, not for runtime :(
vec3 moveHead( in vec3 pos, in vec3 an, in float amount)
{
    pos.y -= -1.0;
    pos.xz = rot(pos.xz,amount*an.x);
    pos.xy = rot(pos.xy,amount*an.y);
    pos.yz = rot(pos.yz,amount*an.z);
    pos.y += -1.0;
    return pos;
}

// the animation state
vec3 animData; // { blink, nose follow up, mouth } 
vec3 animHead; // { head rotation angles }

// SDF of the girl. It is not as efficient as it should, both in terms
// of performance and euclideanness of the returned distance. Among
// other things I tweaked the overal shape of the head though scaling
// right in the middle of the design process (see 1.02 and 1.04 numbers
// below). I should have backpropagated those adjustements to the 
// primitives themselves, but I didn't and now it's too late. So,
// I am paying some cost there.
//
// Generally, she is modeled to camera (her face's shape looks bad from
// other perspectives. She's made of five ellipsoids blended together for
// the face, a cone and three spheres for the nose, a torus for the teeh
// and two quadratic curves for the lips. The neck is a cylinder, the
// hair is made of three quadratic that are repeated multiple times
// through domain repetition and each of them contains three more curves
// in order to make the braids. The hoodie is an ellipsoid deformed with
// two sine waves and cut in half, the neck is an elongated torus section
// and the shoulders are capsules.
//
vec4 map( in vec3 pos, in float time, out float outMat, out vec3 uvw )
{
    outMat = 1.0;

    vec3 oriPos = pos;
    
    // head deformation and transformation
    pos.y /= 1.04;
    vec3 opos;
    opos = moveHead( pos, animHead, smoothstep(-1.2, 0.2,pos.y) );
    pos  = moveHead( pos, animHead, smoothstep(-1.4,-1.0,pos.y) );
    pos.x *= 1.04;
    pos.y /= 1.02;
    uvw = pos;

    // symmetric coord systems (sharp, and smooth)
    vec3 qos = vec3(abs(pos.x),pos.yz);
    vec3 sos = vec3(sqrt(qos.x*qos.x+0.0005),pos.yz);

    
    
    // head
    float d = sdEllipsoid( pos-vec3(0.0,0.05,0.07), vec3(0.8,0.75,0.85) );
    
    // jaw
    vec3 mos = pos-vec3(0.0,-0.38,0.35); mos.yz = rot(mos.yz,0.4);
    mos.yz = rot(mos.yz,0.1*animData.z);
    float d2 = sdEllipsoid(mos-vec3(0,-0.17,0.16),
                 vec3(0.66+sclamp(mos.y*0.9-0.1*mos.z,-0.3,0.4),
                      0.43+sclamp(mos.y*0.5,-0.5,0.2),
                      0.50+sclamp(mos.y*0.3,-0.45,0.5)));
        
    // mouth hole
    d2 = smax(d2,-sdEllipsoid(mos-vec3(0,0.06,0.6+0.05*animData.z), vec3(0.16,0.035+0.05*animData.z,0.1)),0.01);
    
    // lower lip    
    vec4 b = sdBezier(vec3(abs(mos.x),mos.yz), 
                      vec3(0,0.01,0.61),
                      vec3(0.094+0.01*animData.z,0.015,0.61),
                      vec3(0.18-0.02*animData.z,0.06+animData.z*0.05,0.57-0.006*animData.z));
    float isLip = smoothstep(0.045,0.04,b.x+b.y*0.03);
    d2 = smin(d2,b.x - 0.027*(1.0-b.y*b.y)*smoothstep(1.0,0.4,b.y),0.02);
    d = smin(d,d2,0.19);

    // chicks
    d = smin(d,sdSphere(qos-vec3(0.2,-0.33,0.62),0.28 ),0.04);
    
    // who needs ears
    

    // eye sockets
    vec3 eos = sos-vec3(0.3,-0.04,0.7);
    eos.xz = rot(eos.xz,-0.2);
    eos.xy = rot(eos.xy,0.3);
    eos.yz = rot(eos.yz,-0.2);
    d2 = sdEllipsoid( eos-vec3(-0.05,-0.05,0.2), vec3(0.20,0.14-0.06*animData.x,0.1) );
    d = smax( d, -d2, 0.15 );

    eos = sos-vec3(0.32,-0.08,0.8);
    eos.xz = rot(eos.xz,-0.4);
    d2 = sdEllipsoid( eos, vec3(0.154,0.11,0.1) );
    d = smax( d, -d2, 0.05 );

    vec3 oos = qos - vec3(0.25,-0.06,0.42);
    
    // eyelid
    d2 = sdSphere( oos, 0.4 );
    oos.xz = rot(oos.xz, -0.2);
    oos.xy = rot(oos.xy, 0.2);
    vec3 tos = oos;        
    oos.yz = rot(oos.yz,-0.6+0.58*animData.x);

    //eyebags
    tos = tos-vec3(-0.02,0.06,0.2+0.02*animData.x);
    tos.yz = rot(tos.yz,0.8);
    tos.xy = rot(tos.xy,-0.2);
    d = smin( d, sdTorus(tos,0.29,0.01), 0.03 );
    
    // eyelids
    eos = qos - vec3(0.33,-0.07,0.53);
    eos.xy = rot(eos.xy, 0.2);
    eos.yz = rot(eos.yz,0.35-0.25*animData.x);
    d2 = smax(d2-0.005, -max(oos.y+0.098,-eos.y-0.025), 0.02 );
    d = smin( d, d2, 0.012 );

    // eyelashes
    oos.x -= 0.01;
    float xx = clamp( oos.x+0.17,0.0,1.0);
    float ra = 0.35 + 0.1*sqrt(xx/0.2)*(1.0-smoothstep(0.3,0.4,xx))*(0.6+0.4*sin(xx*256.0));
    float rc = 0.18/(1.0-0.7*smoothstep(0.15,0.5,animData.x));
    oos.y -= -0.18 - (rc-0.18)/1.8;
    d2 = (1.0/1.8)*sdArc( oos.xy*vec2(1.0,1.8), vec2(0.9,sqrt(1.0-0.9*0.9)), rc )-0.001;
    float deyelashes = max(d2,length(oos.xz)-ra)-0.003;
    
    // nose
    eos = pos-vec3(0.0,-0.079+animData.y*0.005,0.86);
    eos.yz = rot(eos.yz,-0.23);
    float h = smoothstep(0.0,0.26,-eos.y);
    d2 = sdCone( eos-vec3(0.0,-0.02,0.0), vec2(0.03,-0.25) )-0.04*h-0.01;
    eos.x = sqrt(eos.x*eos.x + 0.001);
    d2 = smin( d2, sdSphere(eos-vec3(0.0, -0.25,0.037),0.06 ), 0.07 );
    d2 = smin( d2, sdSphere(eos-vec3(0.1, -0.27,0.03 ),0.04 ), 0.07 );
    d2 = smin( d2, sdSphere(eos-vec3(0.0, -0.32,0.05 ),0.025), 0.04 );        
    d2 = smax( d2,-sdSphere(eos-vec3(0.07,-0.31,0.038),0.02 ), 0.035 );
    d = smin(d,d2,0.05-0.03*h);
    
    // mouth
    eos = pos-vec3(0.0,-0.38+animData.y*0.003+0.01*animData.z,0.71);
    tos = eos-vec3(0.0,-0.13,0.06);
    tos.yz = rot(tos.yz,0.2);
    float dTeeth = sdTorus(tos,0.15,0.015);
    eos.yz = rot(eos.yz,-0.5);
    eos.x /= 1.04;

    // nose-to-upperlip connection
    d2 = sdCone( eos-vec3(0,0,0.03), vec2(0.14,-0.2) )-0.03;
    d2 = max(d2,-(eos.z-0.03));
    d = smin(d,d2,0.05);

    // upper lip
    eos.x = abs(eos.x);
    b = sdBezier(eos, vec3(0.00,-0.22,0.17),
                      vec3(0.08,-0.22,0.17),
                      vec3(0.17-0.02*animData.z,-0.24-0.01*animData.z,0.08));
    d2 = length(b.zw/vec2(0.5,1.0)) - 0.03*clamp(1.0-b.y*b.y,0.0,1.0);
    d = smin(d,d2,0.02);
    isLip = max(isLip,(smoothstep(0.03,0.005,abs(b.z+0.015+abs(eos.x)*0.04))
                 -smoothstep(0.45,0.47,eos.x-eos.y*1.15)));

    // valley under nose
    vec2 se = sdSegment(pos, vec3(0.0,-0.45,1.01),  vec3(0.0,-0.47,1.09) );
    d2 = se.x-0.03-0.06*se.y;
    d = smax(d,-d2,0.04);
    isLip *= smoothstep(0.01,0.03,d2);

    // neck
    se = sdSegment(pos, vec3(0.0,-0.65,0.0), vec3(0.0,-1.7,-0.1) );
    d2 = se.x - 0.38;

    // shoulders
    se = sdSegment(sos, vec3(0.0,-1.55,0.0), vec3(0.6,-1.65,0.0) );
    d2 = smin(d2,se.x-0.21,0.1);
    d = smin(d,d2,0.4);
        
    // register eyelases now
    vec4 res = vec4( d, isLip, 0, 0 );
    if( deyelashes<res.x )
    {
        res.x = deyelashes*0.8;
        res.yzw = vec3(0.0,1.0,0.0);
    }
    // register teeth now
    if( dTeeth<res.x )
    {
        res.x = dTeeth;
        outMat = 5.0;
    }
 
    // eyes
    pos.x /=1.05;        
    eos = qos-vec3(0.25,-0.06,0.42);
    d2 = sdSphere(eos,0.4);
    if( d2<res.x ) 
    { 
        res.x = d2;
        outMat = 2.0;
        uvw = pos;
    }
        
    // hair
    {
        vec2 occ_id, tmp;
        qos = pos; qos.x=abs(pos.x);

        vec4 pres = sdHair(pos,vec3(-0.3, 0.55,0.8), 
                               vec3( 0.95, 0.7,0.85), 
                               vec3( 0.4,-1.45,0.95),
                               -0.9,occ_id);

        vec4 pres2 = sdHair(pos,vec3(-0.4, 0.6,0.55), 
                                vec3(-1.0, 0.4,0.2), 
                                vec3(-0.6,-1.4,0.7),
                                0.6,tmp);
        if( pres2.x<pres.x ) { pres=pres2; occ_id=tmp;  occ_id.y+=40.0;}

        pres2 = sdHair(qos,vec3( 0.4, 0.7,0.4), 
                           vec3( 1.0, 0.5,0.45), 
                           vec3( 0.4,-1.45,0.55),
                           -0.2,tmp);
        if( pres2.x<pres.x ) { pres=pres2; occ_id=tmp;  occ_id.y+=80.0;}
    

        pres.x *= 0.8;
        if( pres.x<res.x )
        {
            res = vec4( pres.x, occ_id.y, 0.0, occ_id.x );
            uvw = pres.yzw;
            outMat = 4.0;
        }
    }

    // hoodie
    vec4 tmp = sdHoodie( opos );
    if( tmp.x<res.x )
    {
        res.x = tmp.x;
        outMat = 3.0;
        uvw  = tmp.yzw;
    }

    return res;
}

// SDF of the girl again, but with extra high frequency modeling
// detail. While the previous one is used for raymarching and shadowing,
// this one is used for normal computation. This separation is
// conceptually equivalent to decoupling detail from base geometry
// with "normal maps", but done in 3D and with SDFs, which is way
// simpler and can be done corretly (something rarely seen in 3D
// engines) without any complexity.
/*
vec4 mapD( in vec3 pos, in float time )
{
    float matID;
    vec3 uvw;
    vec4 h = map(pos, time, matID, uvw);
    
    if( matID<1.5 ) // skin
    {
        // pores
        float d = fbm1(iChannel0,120.0*uvw);
        h.x += 0.0015*d*d;
    }
    else if( matID>3.5 && matID<4.5 ) // hair
    {
        // some random displacement to evoke hairs
        float te = texture( iChannel2,vec2( 0.25*atan(uvw.x,uvw.y),8.0*uvw.z) ).x;
        h.x -= 0.02*te;
    }    
    return h;
}
*/

float sdf( vec3 p ) {
    float boxD = sdBox(p, vec3(1.,1.,1.));
    p += vec3(0.0,-0.2,0.0);
    //p *= RotMat(vec3(0.,1.,0.), -pi/2.);
    const float scale = 0.6;
    p *= (1.0 / scale);
    //return map(p).d * scale;
    float matID;
    vec3 uvw;
    return max(boxD, map(p, TIME, matID, uvw).x) * 0.5;
}

#endif

