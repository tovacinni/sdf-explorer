/*
Copyright 2020 @yuntaRobo
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wlKXWc
*/

/******************************************************************************
 This work is a derivative of work by yuntaRobo used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef cable_glsl
#define cable_glsl

const float PI = 3.1415926;
const float TAU = PI * 2.0;
const float E = 0.01;

#define iTime g3d_SceneTime

mat2 rotate2D(float rad)
{
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, s, -s, c);
}

vec2 de(vec3 p)
{
    float d = 100.0;
    float a = 0.0;

    p.yz *= rotate2D(PI / 5.0);
    p.y -= 0.5;

    // reaction
    vec3 reaction = vec3(cos(iTime), 0.0, sin(iTime)) * 3.0;
    p += exp(-length(reaction - p) * 1.0) * normalize(reaction - p);
    
    // cables
    float r = atan(p.z, p.x) * 3.0;
    const int ite = 50;
    for (int i = 0; i < ite; i++)
    {
        r += 0.5 / float(ite) * TAU;
        float s = 0.5 + sin(float(i) * 1.618 * TAU) * 0.25;
        s += sin(iTime + float(i)) * 0.1;
        vec2 q = vec2(length(p.xz) + cos(r) * s - 3.0, p.y + sin(r) * s);
        float dd = length(q) - 0.035;
        a = dd < d ? float(i) : a;
        d = min(d, dd);
    }

    // sphere
    float dd = length(p - reaction) - 0.1;
    a = dd < d ? 0.0 : a;
    d = min(d, dd);

    return vec2(d, a);
}

float sdf(vec3 p)
{
    //p += vec3(-0.11,0.,0.);
    const float scale = 0.23;
    p *= 1. / scale;
    return de(p).x * scale * 0.7;
}

#endif

