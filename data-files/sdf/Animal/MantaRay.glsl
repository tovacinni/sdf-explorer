/*
Copyright 2015 @dakrunch
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4ls3zM
*/


/******************************************************************************
 This work is a derivative of work by dakrunch used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef manta_glsl
#define manta_glsl

float time = g3d_SceneTime;

//--------------------------------------------------------------------------------------
// Utilities.
// Distance from p to ellipsoid the length of whose semi-principal axes is r.x, r.y, r.z

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

float softMin(float a, float b, float k)
{
    // Inigo's soft min implementation
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    // calculate deformed radius, not exact but fast estimate
    float smallestSize = min(min(r.x,r.y),r.z);
    vec3 deformedP = p/r;
    float d = length(deformedP) - 1.0;
    // renormalize - ish
    return d * smallestSize;
}

float wings(in vec3 p) 
{   
    vec3 r = vec3(1.5, 0.15, 0.55);
    float smallestSize = min(min(r.x,r.y),r.z);
    
    // scale and position
    vec3 dp = p/r;
    dp.z -= dp.x*dp.x*0.8; //bend backward
    dp.z -= (dp.x-0.6)*(dp.x-0.5);
    dp.y -= 0.6; // lift up
    
    // shape
    float d = (dp.y*dp.y + dp.z*dp.z);
    d += abs(dp.x);
    d -= 1.0; // radius
    
    return d * smallestSize;
}

float mantabody(in vec3 p)
{
    // body
    float d = sdEllipsoid(p, vec3(0.4,0.3,0.8));
    
    // wings
    if (p.z < 1.0 && p.z > -1.4 &&
        p.y < 1.0 && p.y > -0.2) 
    {
        d = softMin(d, wings(p), 0.4);
    }
    
    vec3 flapsP;
    vec3 flapsScale;
    
    // bottom flaps
    if (p.x < 1.0 && 
        p.z < -0.2 && p.z > -1.4 &&
        p.y < 0.2 && p.y > -0.2) 
    {
        flapsP = p;
        flapsP += vec3(-0.5-p.z*0.2,0.3-p.x*0.5,1.0-p.x*0.2);
        flapsScale = vec3(.09,.08,.25);
        d = softMin(d, sdEllipsoid(flapsP,flapsScale),0.2);
    }
    
    // dorsal fin
    if (p.x < 0.2 && 
        p.z > 0.3 && p.z < 1.0 &&
        p.y > 0.1 && p.y < 0.5) 
    {
        flapsP = p;
        flapsP += vec3(0.,-0.15- 0.2*p.z,-0.7);
        flapsScale = vec3(.03,.1,.2);
        d = softMin(d, sdEllipsoid(flapsP,flapsScale),0.15);
    }
    
    // tail
    if (p.z>0.0) {    
        float taild = length(p.xy);
        d = softMin(d,taild,0.1);
        d = max(d, smoothstep(2.3,2.5,p.z));
    }
    
    
    return d;
}

float animatedManta(in vec3 p) 
{   
    float size = 1.0;
    
    // animate
    float timeloop = time * 2.5 / (size-0.25); // random offset
    p.y+= -sin(timeloop-0.5)*.25 * size;
    //p.y+= sin(time*0.5 + hash(37.*rowId+11.*columnId)*17.) * 2.5;
    p.y+= sin(time*0.5) * 0.1;
    
    vec3 mantap = p/size;
    mantap.x = abs(mantap.x);    
 
    float animation = sin(timeloop-3. - 1.3*mantap.z);
    float animationAmount = pow(mantap.x,1.5);
    // cap max deformation to reduce ray marching aliasing on wings
    animationAmount = min(animationAmount, 2.5); 
    mantap.y += animation * (0.3*animationAmount + 0.15);
    
    float d = mantabody(mantap);
    
    return d*size;
}

float sdf(vec3 p)
{
    p *= RotMat(vec3(0.,1.,0.), pi);
    const float scale = 0.5;
    p *= 1./scale;
    return animatedManta(p) * 0.3 * scale;
}

#endif 
