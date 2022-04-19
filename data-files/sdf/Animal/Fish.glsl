/*
Copyright 2016 Martijn Steinrucken @BigWings
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/llcSz8
*/

/******************************************************************************
 This work is a derivative of work by Matijn Steinrucken used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef fish_glsl
#define fish_glsl

#define B(x,y,z,w) smoothstep(x-z, x+z, w)*smoothstep(y+z, y-z, w)
#define SIN(x) sin(x)*.5+.5

const vec3 lf=vec3(1., 0., 0.);
const vec3 up=vec3(0., 1., 0.);
const vec3 fw=vec3(0., 0., 1.);

const float twopi = 6.283185307179586;
//const float pi = 3.141592653589793238;

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
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

float L2(vec3 p) {return dot(p, p);}
float L2(vec2 p) {return dot(p, p);}

float N1( float x ) { return fract(sin(x)*5346.1764); }
float N2(float x, float y) { return N1(x + y*134.324); }

float remap01(float a, float b, float t) { return (t-a)/(b-a); }

float fmin( float a, float b, float k, float f, float amp) {
    // 'fancy' smoothmin min.
    // inserts a cos wave at intersections so you can add ridges between two unioned objects
    
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    float scale = h*(1.0-h);
    return mix( b, a, h ) - (k+cos(h*pi*f)*amp*k)*scale;
}

float scaleSphere( vec3 p, vec3 scale, float s )
{
    return (length(p/scale)-s)*min(scale.x, min(scale.y, scale.z));
}

struct de {
    // data type used to pass the various bits of information used to shade a de object
    float d;    // distance to the object
    float b;    // bump
    float m;    // material
    float a;    // angle
    float a2;
    
    float d1, d2, d3, d4, d5;   // extra distance params you can use to color your object
    
    vec3 p;     // the offset from the object center
    
    vec3 s1;    // more data storage
};
   

vec3 Scales(vec2 uv, float seed) {
    // returns a scale info texture: x = brightness y=noise z=distance to center of scale
    vec2 uv2 = fract(uv);
    vec2 uv3 = floor(uv);
    
    float rDist = length(uv2-vec2(1., .5));
    float rMask = smoothstep(.5, .45, rDist);
    float rN = N2(uv3.x, uv3.y+seed);
    vec3 rCol = vec3(uv2.x-.5, rN, rDist);
     
    float tDist = length(uv2-vec2(.5, 1.));    
    float tMask = smoothstep(.5, .45, tDist);
    float tN = N2(uv3.x, uv3.y+seed);
    vec3 tCol = vec3(1.*uv2.x, tN, tDist);
    
    float bDist = length(uv2-vec2(.5, 0.));
    float bMask = smoothstep(.5, .45, bDist);
    float bN = N2(uv3.x, uv3.y-1.+seed);
    vec3 bCol = vec3(uv2.x, bN, bDist);
    
    float lDist = length(uv2-vec2(.0, .5));
    float lMask = smoothstep(.5, .45, lDist);
    float lN = N2(uv3.x-1., uv3.y+seed);
    vec3 lCol = vec3(uv2.x+.5, lN, lDist);
    
    vec3 col = rMask*rCol;
    col = mix(col, tCol, tMask);
    col = mix(col, bCol, bMask);
    col = mix(col, lCol, lMask);
    
    return col;
}

de Fish(vec3 p, vec3 n, float camDist) {
    // p = position of the point to be sampled
    // n = per-fish random values
    // camDist = the distance of the fish, used to scale bump effects
    p.x += 1.5;
    p.z += sin(p.x-g3d_SceneTime*2.+n.x*100.)*mix(.15, .25, n.y);
    p.z = abs(p.z);
   
    float fadeDetail = smoothstep(25., 5., camDist);
    
    vec3 P;
    
    float dist;     // used to keep track of the distance to a certain point
    float mask;     // used to mask effects
    float r;
    vec2 dR;
    
    float bump=0.; // keeps track of bump offsets
    
    float lobe = scaleSphere(p-vec3(-1., 0., 0.25), vec3(1., 1., .5), .4);
    float lobe2 = scaleSphere(p-vec3(-1., 0., -0.25), vec3(1., 1., .5), .4);
    
    vec3 eyePos = p-vec3(-1., 0., 0.4);
    float eye = scaleSphere(eyePos, vec3(1., 1., .35), .25);
    float eyeAngle = atan(eyePos.x, eyePos.y);
    
    float snout = scaleSphere(p-vec3(-1.2, -0.2, 0.), vec3(1.5, 1., .5), .4);
    P = p-vec3(-1.2, -0.6, 0.);
    P = P*RotMat(vec3(0., 0., 1.), .35);
    float jawDn = scaleSphere(P, vec3(1., .2, .4), .6);
    float jawUp = scaleSphere(P-vec3(-0.3, 0.15, 0.), vec3(.6, .2, .3), .6);
    float mouth = fmin(jawUp, jawDn, 0.03, 5., .1);
    snout = smin(snout, mouth, 0.1);
    
    float body1 = scaleSphere(p-vec3(.6, -0., 0.), vec3(2., 1., .5), 1.);
    float body2 = scaleSphere(p-vec3(2.4, 0.1, 0.), vec3(3., 1., .4), .6); 

    P = p-vec3(-1., 0., 0.);
    
    float angle = atan(P.y, P.z);
    vec2 uv = vec2(remap01(-2., 3., p.x), (angle/pi)+.5); // 0-1
    vec2 uv2 = uv * vec2(2., 1.)*20.;
    
    vec3 sInfo = Scales(uv2, n.z);
    float scales = -(sInfo.x-sInfo.z*2.)*.01;
    scales *= smoothstep(.33, .45, eye)*smoothstep(1.8, 1.2, eye)*smoothstep(-.3, .0, p.x);
    
    // gill plates
    P = p-vec3(-.7, -.25, 0.2);
    P = P * RotMat(vec3(0., 1., 0.), .4);
    float gill = scaleSphere(P, vec3(1., .9, .15), .8);
    
    // fins
    float tail = scaleSphere(p-vec3(4.5, 0.1, 0.), vec3(1., 2., .2), .5);
    dR = (p-vec3(3.8, 0.1, 0.)).xy;
    r = atan(dR.x, dR.y);
    
    mask = B(0.45, 2.9, .2, r) * smoothstep(.2*.2, 1., L2(dR));
    
    bump += sin(r*70.)*.005*mask;
    tail += (sin(r*5.)*.03 + bump)*mask;
    tail += sin(r*280.)*.001*mask*fadeDetail;
    
    float dorsal1 = scaleSphere(p-vec3(1.5, 1., 0.), vec3(3., 1., .2), .5);
    float dorsal2 = scaleSphere(p-vec3(0.5, 1.5, 0.), vec3(1., 1., .1), .5);
    dR = (p-vec3(0.)).xy;
    r = atan(dR.x, dR.y);
    dorsal1 = smin(dorsal1, dorsal2, .1);
    
    mask = B(-.2, 3., .2, p.x);
    bump += sin(r*100.)*.003*mask;
    bump += (1.-pow(sin(r*50.)*.5+.5, 15.))*.015*mask;
    bump += sin(r*400.)*.001*mask*fadeDetail;
    dorsal1 += bump;
    
    float anal = scaleSphere(p-vec3(2.6, -.7, 0.), vec3(2., .7, .1), .5);
    anal += sin(r*300.)*.001;
    anal += sin(r*40.)*.01;
    
    
    // Arm fins
    P = p-vec3(0.7, -.6, 0.55);
    dR = (p-vec3(0.3, -.4, 0.6)).xy;
    r = atan(dR.x, dR.y);
    P = P*RotMat(lf, .2);
    P = P*RotMat(up, .2);
    mask = B(1.5, 2.9, .1, r);          // radial mask
    mask *= smoothstep(.1*.1, .6*.6, L2(dR));   // distance mask
    float arm = scaleSphere(P, vec3(2., 1., .2), .2);
    arm += (sin(r*10.)*.01 + sin(r*100.)*.002) * mask;
   
    // Breast fins
    P = p-vec3(0.9, -1.1, 0.2);
    P = P*RotMat(fw, .4);
    P = P*RotMat(lf, .4);
    dR = (p-vec3(0.5, -.9, 0.6)).xy;
    r = atan(dR.x, dR.y);
    mask = B(1.5, 2.9, .1, r);          // radial mask
    mask *= smoothstep(.1*.1, .4*.4, L2(dR));
    float breast = scaleSphere(P, vec3(2., 1., .2), .2);
    breast += (sin(r*10.)*.01 + sin(r*60.)*.002)*mask;
    
    
    de f;
    f.p = p;
    f.a = angle;
    f.a2 = eyeAngle;
    f.d4 = length(eyePos);
    f.m = 1.;
    
    f.d1 = smin(lobe, lobe2, .2); // d1 = BODY
    f.d1 = smin(f.d1, snout, .3);
    f.d1 += 0.005*(sin(f.a2*20.+f.d4)*sin(f.a2*3.+f.d4*-4.)*SIN(f.d4*10.));
    f.d1 = smin(f.d1, body1, .15);
    f.d1 = smin(f.d1, body2, .3);
    f.d1 += scales*fadeDetail;
    f.d1 = fmin(f.d1, gill, .1, 5., 0.1);
    
    float fins = min(arm, breast);
    fins = min(fins, tail);
    fins = min(fins, dorsal1);
    fins = min(fins, anal);    
        
    f.d = smin(f.d1, fins, .05);
    f.d = fmin(f.d, eye, .01, 2., 1.);
    f.d *= .8;
    
    f.d2 = dorsal1;
    f.d3 = tail;
    f.d5 = mouth;
    f.b = bump;
    
    f.s1 = sInfo;
    
    return f;
}

de map( vec3 p, vec3 rd) {
    // returns a vec3 with x = distance, y = bump, z = mat transition w = mat id
    de o;
    o.d = 1000.;
    o = Fish(p, vec3(0.), 0.); 
    return o;
}

de map( in vec3 p){return map(p, vec3(1.));}

float sdf( vec3 p ) {
    p += vec3(0.0,0.1,0.0);
    p *= RotMat(vec3(0.,1.,0.), -pi/2.);
    const float scale = 0.22;
    p *= (1.0 / scale);
    return map(p).d * scale;
}

#endif
