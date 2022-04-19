/*
Copyright 2019 @eiffie
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

/******************************************************************************
 * The MIT License (MIT)
 * Copyright (c) 2021, NVIDIA CORPORATION.
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#ifndef chain_glsl
#define chain_glsl

#define TWISTS 4.5
#define TAO 6.2831853

const float pdt=10.0/TAO,tdp=TAO/10.0;

vec2 chain_Rot2D(vec2 v, float angle) {return cos(angle)*v+sin(angle)*vec2(v.y,-v.x);}

float Link(vec3 p, float a){
 p.xy=chain_Rot2D(p.xy,a);
 p.y+=1.0+sin(a+60.)*0.2;
 p.yz=chain_Rot2D(p.yz,a*TWISTS+60.);
 return length(vec2(length(max(abs(p.xy)-vec2(0.125,0.025),0.0))-0.1,p.z))-0.02;
}

float DE(in vec3 p){
 float a=atan(p.x,-p.y)*pdt;
 return min(Link(p,floor(0.5+a)*tdp),Link(p,(floor(a)+0.5)*tdp));
}

float sdf(vec3 p)
{
    p += vec3(-0.11,0.,0.);
    const float scale = 0.7;
    p *= 1. / scale;
    return DE(p) * scale * 0.6;
}

#endif 
