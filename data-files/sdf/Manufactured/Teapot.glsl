/*
Copyright 2020 @klk
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/3lG3Dc
*/

/******************************************************************************
 This work is a derivative of work by klk used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef teapot_glsl
#define teapot_glsl

#define float3 vec3
#define float2 vec2
#define float4 vec4
#define float3x3 mat3

const float MAX_RAY_LENGTH=10000.0;

// Smooth combine functions from IQ

float teapot_smin(float a, float b, float k)
{
    float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h)-k*h*(1.0-h);
}

float teapot_smax( float a, float b, float k)
{
    return -teapot_smin(-a,-b,k);
}

float teapot_smin( float a, float b)
{
    return teapot_smin(a,b,0.1);
}

float teapot_smax( float a, float b)
{
    return teapot_smax(a,b,0.1);
}

float sq(float x){return x*x;}

float Torus(float x, float y, float z, float R, float r)
{
    vec2 xz = vec2(x, z); 
    vec2 q = vec2(length(xz)-R,y); 
    return length(q)-r;
}

float Torus(vec3 p, float R, float r)
{
    vec2 q = vec2(length(p.xz)-R,p.y);
    return length(q)-r;
}


float Lid(float x, float y, float z)
{
    float v=sqrt(sq(x)+sq(y-0.55)+sq(z))-1.4;
    v=teapot_smin(v,Torus(y-2.,x,z,.2,.08),.1);
    v=teapot_smax(v,-sqrt(sq(x)+sq(y-0.55)+sq(z))+1.3);
    v=teapot_smax(v,sqrt(sq(x)+sq(y-2.5)+sq(z))-1.3);

    v=teapot_smax(v,-sqrt(sq(x-.25)+sq(z-.35))+0.05,.05);
    v=teapot_smin(v,Torus(x,(y-1.45)*.75,z,.72,.065),.2);
    return v;
}

float Nose(float x, float y, float z)
{
    z-=sin((y+0.8)*3.6)*.15;
    
    float v=sqrt(sq(x)+sq(z));
    
    v=abs(v-.3+sin(y*1.6+.5)*0.18)-.05;
    v=teapot_smax(v,-y-1.);
    v=teapot_smax(v,y-0.85,.075);
    
    return v;
}

float Teapot(float3 p)
{
    float x=p.x;
    float y=p.y;
    float z=p.z;

    float v=0.0;
    v=sqrt(x*x+z*z)-1.2-sin(y*1.5+2.0)*.4;
    v=teapot_smax(v,abs(y)-1.,0.3);


    
    float v1=sqrt(x*x*4.+sq(y+z*.1)*1.6+sq(z+1.2))-1.0;
    v1=teapot_smax(v1,-sqrt(sq(z+1.2)+sq(y+z*.12+.015)*1.8)+.8,.3);
    
    v=teapot_smin(v,Torus(y*1.2+.2+z*.3,x*.75,z+1.25+y*.2,.8,.1),.25);
    v=teapot_smin(v,sqrt(sq(x)+sq(y-1.1)+sq(z+1.8))-.05,.32);

    float v3=Nose(x,(y+z)*sqrt(.5)-1.6,(z-y)*sqrt(.5)-1.1);

    v=teapot_smin(v,v3,0.2);
    
    v=teapot_smax(v,teapot_smin(sin(y*1.4+2.0)*0.5+.95-sqrt(x*x+z*z),y+.8, .2));
    v=teapot_smax(v,-sqrt(sq(x)+sq(y+.15)+sq(z-1.5))+.12);

    v=teapot_smin(v,Torus(x,y-0.95,z,0.9,.075));
    v=teapot_smin(v,Torus(x,y+1.05,z,1.15,.05),0.15);
    
    
    float v2=Lid(x,y+.5,z);
    v=min(v,v2);

    return v;
}

float sdf(vec3 p)
{
    const float scale = 0.3;
    p *= 1. / scale;
    return Teapot(p) * scale * 0.8;
}

#endif
