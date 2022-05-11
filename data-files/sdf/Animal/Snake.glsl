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


#define MAX_STEPS 200
#define MAX_DIST 60.
#define SURF_DIST .01

#define CAM_MOVE 1.

#define S smoothstep

#define MAT_TONGUE 1.
#define MAT_HEAD 2.
#define MAT_BODY 3.
#define MAT_EYE 4.

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

float sabs(float x,float k) {
    float a = (.5/k)*x*x+k*.5;
    float b = abs(x);
    return b<k ? a : b;
}

vec2 RaySphere(vec3 ro, vec3 rd, vec4 s) {
    float t = dot(s.xyz-ro, rd);
    vec3 p = ro + rd * t;

    float y = length(s.xyz-p);

    vec2 o = vec2(MAX_DIST,MAX_DIST);

    if(y<s.w) {
        float x = sqrt(s.w*s.w-y*y);
        o.x = t-x;
        o.y = t+x;
    }

    return o;
}

// From IQ
float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k) {
    return smin(a, b, -k);
}

mat2 Rot(float a) {
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

    gv.y = sabs(gv.y,point);

    float w = .5+overlap;
    vec2 p1 = (gv+vec2(overlap,-gv.x*skew))*vec2(1,1.8);
    float a1 = atan(p1.x-w, p1.y);

    float waveAmp = .02;
    float waves = 10.;
    float w1 = sin(a1*waves);
    float s1 = S(w, w*blur, length(p1)+w1*waveAmp);
    s1 +=  w1*.1*s1;
    s1 *= mix(1., .5-gv.x, overlap*2.);

    gv.x -= 1.;
    vec2 p2 = (gv+vec2(overlap,-gv.x*skew))*vec2(1,1.8);
    float a2 = atan(p2.x-w, p2.y);
    float w2 = sin(a2*waves);
    float s2 = S(w, w*blur, length(p2)+w2*waveAmp);
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
    float t = g3d_SceneTime*.3;
    float neckFade = S(3., 10., p.z);

    p.x += sin(p.z*.15-t)*neckFade*4.;
    p.y += sin(p.z*.1-t)*neckFade;

    vec2 st = vec2(atan(p.x, p.y), p.z);

    float body = length(p.xy)-(.86+S(2., 15., p.z)*.6-p.z*.01);
    body = max(.8-p.z, body);

    vec4 scales = vec4(0);
    if(body<.1) {
        vec2 uv = vec2(-st.y*.25, st.x/6.2832+.5);
        float a = sin(st.x+1.57)*.5+.5;
        float fade = a;
        a = S(.1, .4, a);

        uv.y = 1.-abs(uv.y*2.-1.);
        uv.y *= (uv.y-.2)*.4;
        scales = ScaleTex(uv*1.3, .3*a, .3*a, .01, .8);
        body += scales.x*.02*(fade+.2);
    }

    body += S(-.4, -.9, p.y)*.2;    // flatten bottom
    return vec3(body, scales.zw);
}

float GetHeadScales(vec3 p, vec3 eye, vec3 mouth, float md) {
    float t = g3d_SceneTime;

    float jitter = .5;
    jitter *= S(.1, .3, abs(md));
    jitter *= S(1.2, .5, p.z);

    p.z += .5;
    p.z *= .5;

    p.yz *= Rot(.6);
    float y = atan(p.y, p.x);
    vec2 gv = vec2(p.z*5., y*3.);

    vec2 id = floor(gv);

    gv = fract(gv)-.5;

    float d=MAX_DIST;
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
    d *= S(.0, .5, length(p.xy)-.1);
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
    float brows = S(.1, .8, p.y-(p.z+.9)*.5);
    brows *= brows*brows;
    brows *= S(.3, -.2, eye);
    d -= brows*.5;
    d += S(.1, -.2, eye)*.1;

    vec2 mp = p.yz-vec2(3.76+S(-.71, -.14, p.z)*(p.z+.5)*.2, -.71);
    float mouth = length(mp)-4.24;
    d += S(.03,.0,abs(mouth))*S(.59,.0, p.z)*.03;

    d += GetHeadScales(p, ep, mp.xyy, mouth);

    d = min(d, eye);

    float nostril = length(p.zy-vec2(-1.9-p.x*p.x, .15))-.05;
    d = smax(d, -nostril,.05);
    return d;
}

float sdTongue(vec3 p) {
    float t = g3d_SceneTime*3.;

    float inOut = S(.7, .8, sin(t*.5));

    if(p.z>-2.||inOut==0.) return MAX_DIST;     // early out

    float zigzag = (abs(fract(t*2.)-.5)-.25)*4.; // flicker
    float tl = 2.5; // length

    p+=vec3(0,0.27,2);
    p.z *= -1.;
    float z = p.z;
    p.yz *= Rot(z*.4*zigzag);
    p.z -= inOut*tl;

    float width = S(0., -1., p.z);
    float fork = 1.-width;

    float r = mix(.05, .02, fork);

    p.x = sabs(p.x, .05*width*width);
    p.x -= r+.01;
    p.x -= fork*.2*inOut;

    return length(p-vec3(0,0,clamp(p.z, -tl, 0.)))-r;
}

float GetDist(vec3 P) {

    vec3 p = P;
    p.xz *= Rot(sin(g3d_SceneTime*.3)*.1*S(1., 0., p.z));
    float d = sdTongue(p)*.7;
    d = min(d, sdHead(p));
    d = smin(d, sdBody(P).x, .13);

    return d;
}

float sdf(vec3 p) {
    p *= RotMat(vec3(0.,1.,0.), pi);
    float scale = 0.25;
    p *= 1.0 / scale;
    return min(1.0, GetDist(p) * scale);
}

#endif
