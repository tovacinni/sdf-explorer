/*
Copyright 2020 Martijn Steinrucken @BigWings
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wlVSDK
*/

/******************************************************************************
 This work is a derivative of work by Martijn Steinrucken used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef snake_glsl
#define snake_glsl

#define CAM_MOVE 1.
#define SNAKE_MAX_DIST 1.

#define MAT_TONGUE 1.
#define MAT_HEAD 2.
#define MAT_BODY 3.
#define MAT_EYE 4.

float iTime = g3d_SceneTime; //default 60.

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}
float smax(float a, float b, float k) {
    return smin(a, b, -k);
}
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( in vec3 p, in vec3 b )
{
    vec3 d = abs(p) - b;
    return min( max(max(d.x,d.y),d.z),0.0) + length(max(d,0.0));
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

// From Dave Hoskins
vec2 Hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float Hash21(vec2 p) {
    p = fract(p*vec2(123.1031, 324.1030));
    p += dot(p, p+33.33);
    return fract(p.x*p.y);
}

float snake_sabs(float x,float k) {
    float a = (.5/k)*x*x+k*.5;
    float b = abs(x);
    return b<k ? a : b;
}

// From IQ
float snake_smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}


mat2 snake_Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
    p *= scale;
    return abs(dot(sin(p), cos(p.zxy))+bias)/scale - thickness;
}

float sdSph(vec3 p, vec3 pos, vec3 squash, float r) {
    squash = 1./squash;
    p = (p-pos)*squash;
    return (length(p)-r)/max(squash.x, max(squash.y, squash.z));
}


vec4 Scales(vec2 uv, float overlap, float skew, float point, float blur) {
    
    vec2 gv = fract(uv*5.)-.5;
    vec2 id = floor(uv*5.);
    
    float m = 0.;
    
    gv.y = snake_sabs(gv.y,point);
    
    float w = .5+overlap;
    vec2 p1 = (gv+vec2(overlap,-gv.x*skew))*vec2(1,1.8);
    float a1 = atan(p1.x-w, p1.y);
    
    float waveAmp = .02;
    float waves = 10.;
    float w1 = sin(a1*waves);
    float s1 = smoothstep(w, w*blur, length(p1)+w1*waveAmp);
    s1 +=  w1*.1*s1;
    s1 *= mix(1., .5-gv.x, overlap*2.);
    
    gv.x -= 1.;
    vec2 p2 = (gv+vec2(overlap,-gv.x*skew))*vec2(1,1.8);
    float a2 = atan(p2.x-w, p2.y);
    float w2 = sin(a2*waves);
    float s2 = smoothstep(w, w*blur, length(p2)+w2*waveAmp);
    s2 += w2*.1*s2;
    
    s2 *= mix(1., .5-gv.x, overlap*2.);
    
    if(s1>s2) {
        m += s1;
        m -= dot(p1,p1);
    } else {
        m += s2;
        m -= dot(p2,p2);
        id.x += 1.;
    }

    return vec4(1.-m, 0., id);
}

vec4 ScaleTex(vec2 uv, float overlap, float skew, float point, float blur) {

    uv *= 2.;
    vec4 s1 = Scales(uv, overlap, skew, point, blur);
    vec4 s2 = Scales(uv+.1, overlap, skew, point, blur);
    s2.zw -= .5;
    
    return s1.x<s2.x ? s1 : s2;
}


vec3 sdBody(vec3 p) {
    float t = iTime*.3;
    float neckFade = smoothstep(3., 10., p.z);
   
    p.x += sin(p.z*.15-t)*neckFade*4.;
    p.y += sin(p.z*.1-t)*neckFade;
    
    vec2 st = vec2(atan(p.x, p.y), p.z);
    
    float body = length(p.xy)-(.86+smoothstep(2., 15., p.z)*.6-p.z*.01);
    body = max(.8-p.z, body);   
    
    vec4 scales = vec4(0);
    if(body<.1) {
        vec2 uv = vec2(-st.y*.25, st.x/6.2832+.5);
        float a = sin(st.x+1.57)*.5+.5;
        float fade = a;
        a = smoothstep(.1, .4, a);

        uv.y = 1.-abs(uv.y*2.-1.);
        uv.y *= (uv.y-.2)*.4;
        scales = ScaleTex(uv*1.3, .3*a, .3*a, .01, .8);
        body += scales.x*.02*(fade+.2);
    }
    
    body += smoothstep(-.4, -.9, p.y)*.2;   // flatten bottom
    return vec3(body, scales.zw);
}

float GetHeadScales(vec3 p, vec3 eye, vec3 mouth, float md) {    
    float t = iTime;
  
    float jitter = .5;
    jitter *= smoothstep(.1, .3, abs(md));
    jitter *= smoothstep(1.2, .5, p.z);
    
    p.z += .5;
    p.z *= .5;
    
    p.yz *= snake_Rot(.6);
    float y = atan(p.y, p.x);
    vec2 gv = vec2(p.z*5., y*3.);

    vec2 id = floor(gv);
    
    gv = fract(gv)-.5;
    
    float d=SNAKE_MAX_DIST;
    for(float y=-1.; y<=1.; y++) {
        for(float x=-1.; x<=1.; x++) {
            vec2 offs = vec2(x, y);

            vec2 n = Hash22(id+offs);
            vec2 p = offs+sin(n*6.2831)*jitter;
            p -= gv;
            
            float cd = dot(p,p);
            if(cd<d) d = cd;
        }
    }
    
    d += sin(d*20.)*.02;    
    d *= smoothstep(.0, .5, length(p.xy)-.1);
    return d*.06;
}

float sdHead(vec3 p) {    
    p.x = abs(p.x*.9);
    float d = sdSph(p, vec3(0,-.05,.154), vec3(1,1,1.986),1.14); 
    d = smax(d, length(p-vec3(0,7.89,.38))-8.7, .2);
    d = smax(d, length(p-vec3(0,-7.71,1.37))-8.7, .15); // top
    
    d = smax(d, 8.85-length(p-vec3(9.16,-1.0,-3.51)), .2);  // cheeks
    
    vec3 ep = p-vec3(.54,.265,-.82);
    float eye = length(ep)-.35;
    float brows = smoothstep(.1, .8, p.y-(p.z+.9)*.5);
    brows *= brows*brows;
    brows *= smoothstep(.3, -.2, eye);
    d -= brows*.5;
    d += smoothstep(.1, -.2, eye)*.1;
    
    vec2 mp = p.yz-vec2(3.76+smoothstep(-.71, -.14, p.z)*(p.z+.5)*.2, -.71); 
    float mouth = length(mp)-4.24;
    d += smoothstep(.03,.0,abs(mouth))*smoothstep(.59,.0, p.z)*.03;
    
    d += GetHeadScales(p, ep, mp.xyy, mouth);
    
    d = min(d, eye);
    
    float nostril = length(p.zy-vec2(-1.9-p.x*p.x, .15))-.05;
    d = smax(d, -nostril,.05);
    return d;
}

float sdTongue(vec3 p) {
    float t = iTime*3.;
   
    float inOut = smoothstep(.7, .8, sin(t*.5));
    
    if(p.z>-2.||inOut==0.) return SNAKE_MAX_DIST;       // early out
    
    float zigzag = (abs(fract(t*2.)-.5)-.25)*4.; // flicker
    float tl = 2.5; // length
    
    p+=vec3(0,0.27,2);
    p.z *= -1.;
    float z = p.z;
    p.yz *= snake_Rot(z*.4*zigzag);
    p.z -= inOut*tl;
    
    float width = smoothstep(0., -1., p.z);
    float fork = 1.-width;
    
    float r = mix(.05, .02, fork);
    
    p.x = snake_sabs(p.x, .05*width*width);
    p.x -= r+.01;
    p.x -= fork*.2*inOut;

    return length(p-vec3(0,0,clamp(p.z, -tl, 0.)))-r;
}

float GetDist(vec3 P) {
    
    vec3 p = P;
    //p.xz *= snake_Rot(sin(iTime*.3)*.1*smoothstep(1., 0., p.z));
    float d = sdTongue(p)*.7;
    d = min(d, sdHead(p));
    d = snake_smin(d, sdBody(P).x, .13);
    
    return d;
}

float sdf(vec3 p) {
    float boxD = sdBox(p, vec3(1.,1.,1.));
    p *= RotMat(vec3(0.,1.,0.), pi);
    float scale = 0.25;
    p *= 1.0 / scale;
    //return max(boxD, GetDist(p) * scale) * 0.8;
    return min(1.0, GetDist(p) * scale) * 0.8;
}

#endif
