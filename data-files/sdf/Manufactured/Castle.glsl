/*
Copyright 2020 @sukupaper
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/WdXfRS
*/

/******************************************************************************
 This work is a derivative of work by sukupaper used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef castle_glsl
#define castle_glsl

float t;
float aa;

mat2 rot(float a) { float c = cos(a); float s = sin(a); return mat2(c,s,-s,c);}
float castle_rand(vec2 st){ return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.585); }

// 2D Primitives
float sq(vec2 p, vec2 s, float r) { return length(max(abs(p) - s,0.)) - r;}

// df operations
float ext(float d, vec3 p, float h) {
    vec2 w = vec2(d,abs(p.z) - h);
    return min(max(w.x,w.y),0.) + length(max(w,0.));
}
float smoothunion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

// 3D Primitives
float sph(vec3 p, float s) { return length(p) - s; }
float box(vec3 p, vec3 s, float r) { return length(max(abs(p) - s,0.)) - r;}
float cyl2( vec3 p, float h, float r ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return max(length(max(abs(p.y) - h,0.)) - .01, length(p.xz) - r) - .01;
}
float hollowcyl( vec3 p, float h, float r ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return max(length(max(abs(p.y) - h,0.)) - .01, abs(length(p.xz) - r) - .0) - .01;
}
float door(vec3 p, float s) {
    p *= s;
    float d2d = sq(p.xy,vec2(-.05,.515),.3);
    float d = ext(d2d,p,.2);
    return d/s;
}
float doors1(vec3 p, float s) {
    p *= s;
    float d = max(box(p,vec3(.9,1.,.15),.01),-door(p - vec3(0.,-1.3,(-0.525)),.4));
    p.x = abs(p.x);
    d = max(d,-door(p - vec3(0.3,-.5,(-0.1)),1.2));
    d = max(d,-box(p - vec3(0.3,-0.15,0.),vec3(.04,.08,.2),.001));
    d = max(d,-box(p - vec3(0.,0.35,0.),vec3(.04,.08,.2),.001));
    return d/s;
}
float towers1(vec3 p) {
    p.x -= .65;
    float d = hollowcyl(p,.51,.2) - .004*step(0.5,fract(1.5*p.y));
    vec3 p1 = p; p1.x = abs(p.x) - .02; p1.z += .1;
    d = max(d,-box(p1,vec3(.005,.02,5.),.001));
    d = max(d,-box(p1 + vec3(0.,.325,0.),vec3(.005,.02,5.),.001));
    d = max(d,-box(p1 - vec3(0.,.325,0.),vec3(.005,.02,5.),.001));
    p.y -= .5;
    d = smoothunion(d,sph(p,.19),.02);
    return d;
}

float towersAndDoors(vec3 p, float s) {
    p *= s;
    p.x = abs(p.x) - .375;
    float d1 = doors1(p*vec3(1.,1.,-1.),1.992);
    float d2 = towers1(p);
    float d = min(d1,d2);
    return ((d - .005*smoothstep(0.45,0.455,p.y)) + .0001*castle_rand(floor(p.xy*vec2(.75,1.)*180.)))/s;
}

float buildings(vec3 p, float s) {
    float a = atan(p.x,p.z);
    float l = length(p.xz);
    vec3 rP = vec3(fract(a*3.03*s) - .5,fract(p.y*13.) - .5,l);
    float d = cyl2(p, .38,.2*s);
    d = max(d,-box(rP,vec3(.075,.15,10.),.001));
    d = min(d,sph((p - vec3(0.,0.4,0.))*vec3(1.,1.2,1.),.210*s));
    return d;
}

float df(vec3 p) {
    p.zy *= rot(cos(t*.2)*0. + 3.14*.25*.0 - .2);
    p.xz *= rot(t*.05);
    
    float a = atan(p.x,p.z);
    float l = length(p.xz);
    vec3 rP = vec3(fract(a*3.024) - .5,p.y,l - 2.5);
    vec3 rPfloor = vec3(floor(a*3.024) - .5,p.y,l - 2.5);
    vec3 rPnorm = vec3(a,p.y,l - 2.5);
    vec3 rP1 = vec3(fract((a + .2)*2.7058) - .5,p.y - .5,l - 2.2);
    vec3 rP2 = vec3(fract((a + .3)*2.285) - .5,p.y - 1.,l - 1.9);
    
    // 3 walls
    float d = 10e9;
    d = towersAndDoors(rP,2.065);
    d = max(d, -rP.y - (.25 - .01*castle_rand(floor(rP.xz*150.)) - .04*castle_rand(floor(rP.xz*20. + rPfloor.xz*20.)) + .02 ));
    d = min(d, towersAndDoors(rP1,2.065));
    d = min(d, towersAndDoors(rP2,2.065));
    
    // "grid" structure below
    float div = .35;
    vec3 pp; pp.y = rP.y; pp.xz = mod(rP.xz,div) - div*.5;
    float dGrid = max(box(pp,vec3(.2,.17 - .1*castle_rand(floor(rP.xz*5.)),.2),.01), -box(pp,vec3(.15,1.,.15),.01));
    dGrid = max(dGrid,sph(p,2.45));
    d = min(d,dGrid);
    
    // main sphere
    vec3 pSph = p;
    pSph.y += .18;
    d = min(d,max(sph(pSph,1.6 - .025*castle_rand(floor(rPnorm.xz*4.))),pSph.y - 0.44));
    
    // buildings
    p.y -= .25;
    vec3 rP3 = vec3(fract(a*1.1) - .5,p.y - 1.,l - 1.2);
    p.y -= .1;
    vec3 rP4 = vec3(fract((a*1.6 + 1.)*.25)*2. - .5,p.y - 1.,l - .8);
    vec3 rP5 = vec3(fract((a*.7 + 0.)) - .5,p.y - 1.,l - .7);
    p.y -= .1;
    vec3 rP6 = vec3(fract(a*.5) - .5,p.y - 1.,l - .5);
    d = min(d,buildings(rP3,.4));
    d = min(d,buildings(rP4,1.5));
    d = min(d,buildings(rP5,.8));
    d = min(d,buildings(rP6,.6));
    
    // huge tree
    float varTree = 12. + cos(t*.1);
    p.y += pow(length(p.xz)*.51,4.);
    d = min(d, sph((p - vec3(0.,1.9,0.))*vec3(1.,2.,1.) + fract(cos(p.x*varTree) + sin(p.y*varTree) + sin(p.y*varTree))*.032,1.25));
    
    return d;
}

#define E .001
vec3 castle_normal(vec3 p) {
    vec2 u = vec2(0.,E); float d = df(p);
    return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d);
}


float castle_sdf(vec3 p) {
    //float dist = clamp(pow(distance(p, pInit)*.1,12.0),0.,1.);
    return 0.;
}

float sdf(vec3 p){
    p += vec3(0.,.3,0.);
    const float scale = 0.3;
    p *= 1./scale;
    return df(p) * 0.25 * scale;
}

#endif
