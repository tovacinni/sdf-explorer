/*
Copyright 2013 @P_Malin
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/Msl3Rn
*/

/******************************************************************************
 This work is a derivative of work by P_Malin used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef gear_glsl
#define gear_glsl

const float kPI = 3.141592654;
const float kTwoPI = kPI * 2.0;

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

vec3 DomainRotateSymmetry( const in vec3 vPos, const in float fSteps )
{
    float angle = atan( vPos.x, vPos.z );
    
    float fScale = fSteps / (kPI * 2.0);
    float steppedAngle = (floor(angle * fScale + 0.5)) / fScale;
    
    float s = sin(-steppedAngle);
    float c = cos(-steppedAngle);
    
    vec3 vResult = vec3( c * vPos.x + s * vPos.z, 
                 vPos.y,
                 -s * vPos.x + c * vPos.z);
    
    return vResult;
}

float GetDistanceGear( const in vec3 vPos )
{
    float fOuterCylinder = length(vPos.xz) - 1.05;
    if(fOuterCylinder > 0.5)
    {
        return fOuterCylinder;
    }
    
    vec3 vToothDomain = DomainRotateSymmetry(vPos, 16.0);
    vToothDomain.xz = abs(vToothDomain.xz);
    float fGearDist = dot(vToothDomain.xz,normalize(vec2(1.0, 0.55))) - 0.55;
    float fSlabDist = abs(vPos.y + 0.1) - 0.15;
    
    vec3 vHoleDomain = abs(vPos);
    vHoleDomain -= 0.35;
    float fHoleDist = length(vHoleDomain.xz) - 0.2;
    
    float fBarDist =vToothDomain.z - 0.15;
    fBarDist = max(vPos.y - 0.1, fBarDist);
    
    float fResult = fGearDist;
    fResult = max(fResult, fSlabDist);
    fResult = max(fResult, fOuterCylinder);
    fResult = max(fResult, -fHoleDist);
    
    //fResult = max(fResult, vToothDomain.y + vToothDomain.z * 0.25 - 0.25);    
    //fResult = max(fResult, -max( length(vPos.xz) - 0.75, -vPos.y - 0.01 ) );
    
    fResult = min(fResult, fBarDist);
    return fResult;
}

float sdf(vec3 p)
{
    float boxD = sdBox(p, vec3(1.,1.,1.));
    p *= RotMat(vec3(1.,0.,0.), -pi/2.);
    const float scale = 0.8;
    p *= (1.0 / scale);
    return max(boxD, GetDistanceGear(p)) * scale;
}

#endif
