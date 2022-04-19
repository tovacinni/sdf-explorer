/*
Copyright 2017 Martijn Steinrucken @BigWings
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4sXBRn
*/

/******************************************************************************
 This work is a derivative of work by Martijn Steinrucken used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef jelly_glsl
#define jelly_glsl

#define MAX_DISTANCE 100.

#define iTime g3d_SceneTime

const float halfpi = 1.570796326794896619;

float JELLY_N1( float x ) { return fract(sin(x)*5346.1764); }
float JELLY_N2(float x, float y) { return JELLY_N1(x + y*23414.324); }

float N3(vec3 p) {
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

struct jelly_de {
    // data type used to pass the various bits of information used to shajelly_de a jelly_de object
    float d;    // final distance to field
    float m;    // material
    vec3 uv;
    float pump;
    
    vec3 id;
    vec3 pos;       // the world-space coordinate of the fragment
};
    
// ============== Functions I borrowed ;)

//  3 out, 1 in... DAVE HOSKINS
vec3 N31(float p) {
   vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

// jelly_de functions from IQ
float jelly_smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float jelly_smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( a, b, h ) + k*h*(1.0-h);
}

float sdSphere( vec3 p, vec3 pos, float s ) { return (length(p-pos)-s); }

// From http://mercury.sexy/hg_sdf
vec2 jelly_pModPolar(inout vec2 p, float repetitions, float fix) {
    float angle = pi*2.0/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - (angle/2.)*fix;
    p = vec2(cos(a), sin(a))*r;

    return p;
}

float Dist( vec2 P,  vec2 P0, vec2 P1 ) {
    //2d point-line distance
    
    vec2 v = P1 - P0;
    vec2 w = P - P0;

    float c1 = dot(w, v);
    float c2 = dot(v, v);
    
    if (c1 <= 0. )  // before P0
        return length(P-P0);
    
    float b = c1 / c2;
    vec2 Pb = P0 + b*v;
    return length(P-Pb);
}

vec3 ClosestPoint(vec3 ro, vec3 rd, vec3 p) {
    // returns the closest point on ray r to point p
    return ro + max(0., dot(p-ro, rd))*rd;
}

vec2 RayRayTs(vec3 ro1, vec3 rd1, vec3 ro2, vec3 rd2) {
    // returns the two t's for the closest point between two rays
    // ro+rd*t1 = ro2+rd2*t2
    
    vec3 dO = ro2-ro1;
    vec3 cD = cross(rd1, rd2);
    float v = dot(cD, cD);
    
    float t1 = dot(cross(dO, rd2), cD)/v;
    float t2 = dot(cross(dO, rd1), cD)/v;
    return vec2(t1, t2);
}

float DistRaySegment(vec3 ro, vec3 rd, vec3 p1, vec3 p2) {
    // returns the distance from ray r to line segment p1-p2
    vec3 rd2 = p2-p1;
    vec2 t = RayRayTs(ro, rd, p1, rd2);
    
    t.x = max(t.x, 0.);
    t.y = clamp(t.y, 0., length(rd2));
                
    vec3 rp = ro+rd*t.x;
    vec3 sp = p1+rd2*t.y;
    
    return length(rp-sp);
}

vec2 sph(vec3 ro, vec3 rd, vec3 pos, float radius) {
    // does a ray sphere intersection
    // returns a vec2 with distance to both intersections
    // if both a and b are MAX_DISTANCE then there is no intersection
    
    vec3 oc = pos - ro;
    float l = dot(rd, oc);
    float det = l*l - dot(oc, oc) + radius*radius;
    if (det < 0.0) return vec2(MAX_DISTANCE);
    
    float d = sqrt(det);
    float a = l - d;
    float b = l + d;
    
    return vec2(a, b);
}

float rejelly_map(float a, float b, float c, float d, float t) {
    return ((t-a)/(b-a))*(d-c)+c;
}

jelly_de jelly_map( vec3 p, vec3 id ) {

    //float t = 62.5;//iTime*2.;
    float t = iTime*2.;
    
    float N = N3(id);
    
    jelly_de o;
    o.m = 0.;
    
    float x = (p.y+N*pi*2.0)*1.+t;
    float r = 1.;
    
    float pump = cos(x+cos(x))+sin(2.*x)*.2+sin(4.*x)*.02;
    
    x = t + N*pi*2.0;
    p.y -= (cos(x+cos(x))+sin(2.*x)*.2)*.6;
    p.xz *= 1. + pump*.2;
    
    float d1 = sdSphere(p, vec3(0., 0., 0.), r);
    float d2 = sdSphere(p, vec3(0., -.5, 0.), r);
    
    o.d = jelly_smax(d1, -d2, .1);
    o.m = 1.;
    
    if(p.y<.5) {
        float sway = sin(t+p.y+N*pi*2.0)*smoothstep(.5, -3., p.y)*N*.3;
        p.x += sway*N;  // add some sway to the tentacles
        p.z += sway*(1.-N);
        
        vec3 mp = p;
        mp.xz = jelly_pModPolar(mp.xz, 6., 0.);
        
        float d3 = length(mp.xz-vec2(.2, .1))-rejelly_map(.5, -3.5, .1, .01, mp.y);
        if(d3<o.d) o.m=2.;
        d3 += (sin(mp.y*10.)+sin(mp.y*23.))*.03;
        
        float d32 = length(mp.xz-vec2(.2, .1))-rejelly_map(.5, -3.5, .1, .04, mp.y)*.5;
        d3 = min(d3, d32);
        o.d = jelly_smin(o.d, d3, .5);
        
        if( p.y<.2) {
             vec3 op = p;
            op.xz = jelly_pModPolar(op.xz, 13., 1.);
            
            float d4 = length(op.xz-vec2(.85, .0))-rejelly_map(.5, -3., .04, .0, op.y);
            if(d4<o.d) o.m=3.;
            o.d = jelly_smin(o.d, d4, .15);
        }
    }    
    o.pump = pump;
    o.uv = p;
    
    o.d *= .8;
    return o;
}

float sdf(vec3 p)
{
    p += vec3(0.,-0.6,0.);
    const float scale = 0.26;
    p *= 1. / scale;
    return jelly_map(p, vec3(0.)).d * scale;
}

#endif
