/*
Copyright 2019 Martijn Steinrucken @BigWings
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wdGXzK
*/

/******************************************************************************
 This work is a derivative of work by Martijn Steinrucken used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef cybertruck_glsl
#define cybertruck_glsl

#define S(a, b, t) smoothstep(a, b, t)

#define MAT_BASE 0.
#define MAT_FENDERS 1.
#define MAT_RUBBER 2.
#define MAT_LIGHTS 3.
#define MAT_GLASS 4.
#define MAT_SHUTTERS 5.
#define MAT_GROUND 6.
#define MAT_CAB 6.

// From http://mercury.sexy/hg_sdf
vec2 pModPolar(inout vec2 p, float repetitions, float fix) {
    float angle = 6.2832/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - (angle/2.)*fix;
    p = vec2(cos(a), sin(a))*r;

    return p;
}

float sabs(float x,float k) {
    float a = (.5/k)*x*x+k*.5;
    float b = abs(x);
    return b<k ? a : b;
}
vec2 sabs(vec2 x,float k) { return vec2(sabs(x.x, k), sabs(x.y,k)); }
vec3 sabs(vec3 x,float k) { return vec3(sabs(x.x, k), sabs(x.y,k), sabs(x.z,k)); }

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
    vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    //t = clamp(t, 0., 1.);
    
    vec3 c = a + t*ab;
    
    float x = length(p-c)-r;
    float y = (abs(t-.5)-.5)*length(ab);
    float e = length(max(vec2(x, y), 0.));
    float i = min(max(x, y), 0.);
    
    return e+i;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
    return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float map01(float a, float b, float t) {
    return clamp((t-a)/(b-a), 0., 1.);
}
float map(float t, float a, float b, float c, float d) {
    return (d-c)*clamp((t-a)/(b-a), 0., 1.)+c;
}

vec2 sdCar(vec3 p) {
    float matId=MAT_BASE;
    p.x = sabs(p.x, .5);        // smooth abs to make front rounded
    
    vec2 P = p.yz;
    
    // body
    float d, w;
    
    float frontGlass = dot(P, vec2(0.9493, 0.3142))-1.506; // front
    d = frontGlass;
    
    float topGlass = dot(P, vec2(0.9938, -0.1110))-1.407;
    d = max(d, topGlass); 
    float back = dot(P, vec2(0.9887, -0.16))-1.424;
    d = max(d, back); // back
    
    float side1 = dot(p, vec3(0.9854, -0.1696, -0.0137))-0.580;
    d = max(d, side1); // side 1
    
    float side2 = dot(p, vec3(0.9661, 0.2583, 0.0037))-0.986;
    d = smin(d, side2, -.005);
    d = max(d, dot(P, vec2(-0.1578, -0.9875))-2.056); // rear
    d = max(d, dot(p, vec3(0.0952, -0.1171, 0.9885))-2.154);
    d = max(d, dot(p, vec3(0.5019, -0.1436, 0.8529))-2.051);
    d = max(d, dot(P, vec2(-0.9999, -0.0118))+0.2643); // bottom
    d = max(d, dot(p, vec3(0.0839, -0.4614, 0.8832))-1.770);
    d = max(d, dot(p, vec3(0.0247, -0.9653, 0.2599))-0.196);
    d = max(d, dot(P, vec2(-0.9486, -0.3163))-0.295);
    
    float body = d;
    float car = d;
    if((-frontGlass<car && p.z < 1.8-p.x*p.x*.16 && side2<-.01) ||
       (abs(-topGlass-car)<.01 && p.z>-.6 && p.z < .5 && side2<-.01)) 
        matId = MAT_GLASS;
    
    // bed shutters
    d = max(1.-p.y, max(p.x-.63, abs(p.z+1.44)-.73));
    if(d<-.02) matId = MAT_SHUTTERS;
    
    d = max(d, (-back-.01)-S(.5,1., sin(p.z*100.))*.0);
    
    car = max(car, -d);
    
    // bumper
    d = S(.03, .02, abs(p.y-.55))*.045;
    d -= S(.55, .52, p.y)*.05;
    d *= S(1.3, 1.5, abs(p.z));
    
    float rB = max(p.x-p.y*.15-.21, .45-p.y);
    float fB = max(p.x-.51, abs(.42-p.y)-.02);
    d *= S(.0,.01, mix(rB, fB, step(0.,p.z)));
    if(p.y<.58-step(abs(p.z), 1.3)) matId = MAT_FENDERS;
    
    // lights
    float lt = map01(.5, .8, p.x);
    float lights = map01(.02*(1.+lt), .01*(1.+lt), abs(p.y-(.82+lt*.03)));
    lights *= S(2.08, 2.3, p.z);
    d += lights*.05;
    lights = map01(.01, .0, side1+.0175);
    lights *= step(p.z, -2.17);
    lights *= map01(.01, .0, abs(p.y-1.04)-.025);
    d += lights*.03;
    
    if(d>0.&&matId==0.) matId = MAT_LIGHTS;
    
    if(car<.1) d*= .5;
    car += d;
    
    // step
    car += map(p.y+p.z*.022, .495, .325, 0., .05);//-S(.36, .34, p.y)*.1;
    d = sdBox(p-vec3(0, .32, 0), vec3(.72+p.z*.02, .03, 1.2));
    if(d<car) matId = MAT_FENDERS;
    car = min(car, d);
    
    // windows Holes
    
    d = w = dot(P, vec2(-0.9982, -0.0601))+1.0773;
    d = max(d, dot(P, vec2(0.1597, -0.9872))-0.795);
    d = max(d, dot(P, vec2(0.9931, -0.1177))-1.357);
    d = max(d, dot(P, vec2(0.9469, 0.3215))-1.459);
    //d = max(d, -.03-side2);
    float sideWindow = dot(p, vec3(-0.9687, -0.2481, 0.0106))+0.947;
    sideWindow += map01(0., 1., p.y-1.)*.05;
    if(d<-.005) matId = MAT_GLASS;
    
    d = max(d, sideWindow);
    car = max(car, -d);
    
    // panel lines
    if(car<.1) {
        d = abs(dot(p.yz, vec2(0.0393, 0.9992))+0.575);
        d = min(d, abs(dot(p.yz, vec2(0.0718, 0.9974))-0.3));
        d = min(d, abs(p.z-1.128));
        float panels = S(.005, .0025, d) * step(0., w) * step(.36, p.y);
        
        float handleY = dot(p.yz, vec2(-0.9988, -0.0493))+0.94;
        d = S(.02, .01, abs(handleY))*S(.01, .0, min(abs(p.z-.4)-.1, abs(p.z+.45)-.1));
        panels -= abs(d-.5)*.5;
        
        // charger
        d = S(.02, .01, abs(p.y-.81)-.04)*S(.01, .0, abs(p.z+1.75)-.12);
        panels += abs(d-.5)*.5;
        
        d = S(.005, .0, abs(side2+.015));
        d *= S(.03, .0, abs(frontGlass));
        panels += d;
        
        car += panels *.001;
    }
    
    // fenders
    //front
    d = dot(p, vec3(0.4614, 0.3362, 0.8210))-2.2130;
    d = max(d, dot(p, vec3(0.4561, 0.8893, 0.0347))-1.1552);
    d = max(d, dot(p, vec3(0.4792, 0.3783, -0.7920))+0.403);
    d = max(d, dot(p, vec3(0.4857, -0.0609, -0.8720))+0.6963);
    d = max(d, dot(p, vec3(0.4681, -0.4987, 0.7295))-1.545);
    d = max(d, .3-p.y);
    d = max(d, abs(p.x-.62-p.y*.15)-.07);
    if(d<car) matId = MAT_FENDERS;
    car = min(car, d);
    
    // back
    d = dot(p, vec3(0.4943, -0.0461, 0.8681))+0.4202;
    d = max(d, dot(p, vec3(0.4847, 0.4632, 0.7420))+0.0603);
    d = max(d, dot(p, vec3(0.4491, 0.8935, 0.0080))-1.081);
    d = max(d, dot(p, vec3(0.3819, 0.4822, -0.7885))-1.973);    
    d = max(d, min(.58-p.y, -1.5-p.z));
    d = max(d, .3-p.y);
    d = max(d, abs(side1+.01)-.08);
    if(d<car) matId = MAT_FENDERS;
    car = min(car, d);
    
    //if(car>.1) return vec2(car, matId);
    
    // wheel well
    // front
    d = p.z-2.0635;
    d = max(d, dot(p.yz, vec2(0.5285, 0.8489))-2.0260);
    d = max(d, dot(p.yz, vec2(0.9991, 0.0432))-0.8713);
    d = max(d, dot(p.yz, vec2(0.5258, -0.8506))+0.771);
    d = max(d, 1.194-p.z);
    d = max(d, .5-p.x);
    car = max(car, -d);
    if(d<car) matId = MAT_FENDERS;
    
    // back
    d = p.z+0.908;
    d = max(d, dot(p.yz, vec2(0.5906, 0.8070))+0.434);
    d = max(d, dot(p.yz, vec2(0.9998, 0.0176))-0.7843);
    d = max(d, dot(p, vec3(-0.0057, 0.5673, -0.8235))-1.7892);
    d = max(d, -p.z-1.7795);
    d = max(d, .5-p.x);//.65-p.x
    car = max(car, -d);
    if(d<car) matId = MAT_FENDERS;
    
    return vec2(car, matId);
   
}

vec2 sdWheel(vec3 p) {
    float matId=MAT_RUBBER;
    
    vec3 wp = p;
    float  w = sdCylinder(wp, vec3(-.1, 0,0), vec3(.1, 0,0), .32)-.03;
    float dist = length(wp.zy);
    
    if(dist>.3&&w<.05) {        // wheel detail
        float a = atan(wp.z, wp.y);
        float x = wp.x*20.;
        float tireTop = S(.29, .4, dist);
        float thread = S(-.5, -.3, sin(a*40.+x*x))*.01 * tireTop;
        
        thread *= S(.0, .007, abs(abs(wp.x)-.07+sin(a*20.)*.01));
        thread *= S(.005, .01, abs(wp.x+sin(a*20.)*.03));
        
        w -= thread*2.;
        
        float e = length(wp-vec3(2, .1, 0))-.5;
        w = min(w, e);
    }
    
    if(w>.1) return vec2(w, matId);
    
    wp *= .95;
    wp.yz = pModPolar(wp.yz, 7., 1.);
    float cap = max(p.x-.18, wp.y-.3);
    
    wp.z = abs(wp.z);
    
    float d = map01( .3, .23, wp.y);        // spoke bevel
    d *= map01(.04, .03, wp.z);             // spokes
    d *= map01(-.23, .23, wp.y)*.7;         // spoke gradient
    
    d = max(d, map01(.13, .0, wp.y)*1.5);   // center outside
    d = min(d, map01(.0, .07, wp.y));       // center inside
    d = max(d, .8*step(wp.y, .05));         // middle plateau
    
    d = max(d, .4*map01(.23, .22, dot(wp.zy, normalize(vec2(1., 2.)))));
    cap += (1.-d)*.07;
    cap = max(cap, .05-p.x);
    cap *= .8;
    if(cap<w) matId = MAT_FENDERS;
    
    w = min(w, cap);
    w += S(.3, .0, dist)*.025; // concavivy!
    
    return vec2(w, matId);
}

float sdf(vec3 p) {
    p.y += 0.2;

    const float scale = 0.35;
    p *= (1. / scale);

    float car = sdCar(p).x * 0.8 * scale;
    vec3 wp = p-vec3(0,0,.14);
    wp.xz = abs(wp.xz);
    wp-=vec3(.7383, .365, 1.5);
    
    if(p.z>0.) wp.xz *= Rot(.3*sign(p.x));
    float wheel = sdWheel(wp).x * scale;
    
    return min(car, wheel);
}

#endif
