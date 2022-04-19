/*
Copyright 2014 Alexander Alekseev @TDM
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ldSSzV
*/

/******************************************************************************
 This work is a derivative of work by Alexander Alekseev used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef rock_glsl
#define rock_glsl

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

const float DISPLACEMENT = 0.1;

// distance functions
float plane(vec3 gp, vec4 p) {
    return dot(p.xyz,gp+p.xyz*p.w);
}
float rock_sphere(vec3 p,float r) {
    return length(p)-r;
}
float capsule(vec3 p,float r,float h) {
    p.y -= clamp(p.y,-h,h);
    return length(p)-r;
}
float cylinder(vec3 p,float r,float h) {
    return max(abs(p.y/h),capsule(p,r,h));
}
float box(vec3 p,vec3 s) {
    p = abs(p)-s;
    return max(max(p.x,p.y),p.z);
}
float rbox(vec3 p,vec3 s) {
    p = abs(p)-s;
    return length(p-min(p,0.0));
}
float quad(vec3 p,vec2 s) {
    p = abs(p) - vec3(s.x,0.0,s.y);
    return max(max(p.x,p.y),p.z);
}

// boolean operations
float boolUnion(float a,float b) { return min(a,b); }
float boolIntersect(float a,float b) { return max(a,b); }
float boolSub(float a,float b) { return max(a,-b); }

// smooth operations. thanks to iq
float boolSmoothIntersect(float a, float b, float k ) {
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(a,b,h) + k*h*(1.0-h);
}
float boolSmoothSub(float a, float b, float k ) {
    return boolSmoothIntersect(a,-b,k);
}   

float rock(vec3 p) {    
    float d = rock_sphere(p,1.0);    
    for(int i = 0; i < 9; i++) {
        float ii = float(i);
        float r = 2.5 + hash11(ii);
        vec3 v = normalize(hash31(ii) * 2.0 - 1.0);
        d = boolSub(d,rock_sphere(p+v*r,r * 0.8));
    }
    return d;
}

float map_detailed(vec3 p) {
    float d = rock(p) + fbm3_high(p*4.0,0.4,2.96) * DISPLACEMENT;
    return d;
}

float sdf(vec3 p)
{
    const float scale = 0.8;
    p *= 1./scale;
    return map_detailed(p) * scale * 0.7;
}

#endif
