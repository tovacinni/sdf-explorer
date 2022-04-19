/*
Copyright 2020 @monsterkodi
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/3tGSDz
*/ 

/******************************************************************************
 This work is a derivative of work by monsterkodi used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef skull_glsl
#define skull_glsl

const vec3 v0 = vec3(0,0,0);
const vec3 vx = vec3(1,0,0);
const vec3 vy = vec3(0,1,0);
const vec3 vz = vec3(0,0,1);

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

//  0000000  0000000    00000000
// 000       000   000  000
// 0000000   000   000  000000
//      000  000   000  000
// 0000000   0000000    000

struct SDF {
    vec3  pos;
    vec3  color;
    vec3  normal;
    float dist;
    int   mat;
} skull_sdf;

// 00     00   0000000   000000000  00000000   000  000   000
// 000   000  000   000     000     000   000  000   000 000
// 000000000  000000000     000     0000000    000    00000
// 000 0 000  000   000     000     000   000  000   000 000
// 000   000  000   000     000     000   000  000  000   000

mat3 alignMatrix(vec3 right, vec3 up)
{
    return mat3(right, up, cross(right,up));
}


//  0000000   00000000
// 000   000  000   000
// 000   000  00000000
// 000   000  000
//  0000000   000

float opUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}

float opDiff(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d1, -d2, h) + k*h*(1.0-h);
}

float opInter(float d1, float d2, float k)
{

    float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) + k*h*(1.0-h);
}

float opDiff (float d1, float d2) { return opDiff (d1, d2, 0.0); }
float opUnion(float d1, float d2) { return opUnion(d1, d2, 0.5); }
float opInter(float d1, float d2) { return opInter(d1, d2, 0.2); }

void sdMat(int m, float d) { if (d < skull_sdf.dist) { skull_sdf.dist = d; skull_sdf.mat = m; } }
void sdUni(int m, float d) { sdMat(m, opUnion(d, skull_sdf.dist, 0.5)); }
void sdDif(int m, float d) { sdMat(m, opDiff(d, skull_sdf.dist, 0.5)); }
void sdUni(int m, float f, float d) { sdMat(m, opUnion(d, skull_sdf.dist, f)); }
void sdInt(int m, float f, float d) { float md = opInter(d-f, skull_sdf.dist, 0.0); if (md <= skull_sdf.dist) { skull_sdf.dist = md; skull_sdf.mat = m; }}
void sdDif(int m, float f, float d) { float md = opDiff(skull_sdf.dist, d, f); if (md > skull_sdf.dist) { skull_sdf.dist = md; skull_sdf.mat = m; }}
void sdEmb(int m, float f, float d) { float md = opDiff(skull_sdf.dist, d-f, 0.0); if (md > skull_sdf.dist) { skull_sdf.dist = md; skull_sdf.mat = m; }}
void sdExt(int m, float f, float d) { float md = opInter(d-f, skull_sdf.dist-f, f); if (md <= skull_sdf.dist) { skull_sdf.dist = md; skull_sdf.mat = m; }}

void sdCol(vec3 c, float d) { if (d < skull_sdf.dist) { skull_sdf.dist = d; skull_sdf.mat = -2; skull_sdf.color = c; } }


//  0000000  0000000
// 000       000   000
// 0000000   000   000
//      000  000   000
// 0000000   0000000

float sdSphere(vec3 a, float r)
{
    return length(skull_sdf.pos-a)-r;
}

float sdPlane(vec3 a, vec3 n)
{
    return dot(n, skull_sdf.pos-a);
}

float sdPlane(vec3 n)
{
    return dot(n, skull_sdf.pos);
}

float sdBox(vec3 a, vec3 b, float r)
{
    vec3 q = abs(skull_sdf.pos-a)-(b-r);
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdCube(vec3 a, float s, float r)
{
    return sdBox(a, vec3(s), r);
}

float sdBox(vec3 a, vec3 right, vec3 up, vec3 dim)
{
  vec3  q = skull_sdf.pos-a;
  float x = abs(dot(right, q))-dim.x;
  float y = abs(dot(up,    q))-dim.y;
  float z = abs(dot(cross(right,up), q))-dim.z;
  return max(x,max(y,z));
}

float sdBox(vec3 a, vec3 right, vec3 up, vec3 dim, float r)
{
  vec3 p = skull_sdf.pos;
  skull_sdf.pos -= a;
  skull_sdf.pos *= alignMatrix(right, up);
  float d = sdBox(v0, dim, r);
  skull_sdf.pos = p;
  return d;
}

float sdEllipsoid(vec3 a, vec3 r)
{
    vec3 p = skull_sdf.pos-a;
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdCone(vec3 a, float h, float r)
{
    vec3 p = skull_sdf.pos-a;
    float q = length(p.xz);
    return dot(vec2(h,r),vec2(p.y,q));
}

float sdCone(vec3 a, float r1, float r2, float h)
{
    vec3 p = skull_sdf.pos-a;
    vec2 q = vec2( length(p.xz), p.y );
    
    float b = (r1-r2)/h;
    float c = sqrt(1.0-b*b);
    float k = dot(q,vec2(-b,c));
      
    if( k < 0.0 ) return length(q) - r1;
    if( k > c*h ) return length(q-vec2(0.0,h)) - r2;
          
    return dot(q, vec2(c,b) ) - r1;
}

float sdCapsule(vec3 a, vec3 b, float r)
{
    vec3 ab = b-a;
    vec3 ap = skull_sdf.pos-a;
    float t = dot(ab,ap) / dot(ab,ab);
    t = clamp(t, 0.0, 1.0);
    vec3 c = a + t*ab;
    return length(skull_sdf.pos-c)-r;
}

//  0000000  000   000  000   000  000      000      
// 000       000  000   000   000  000      000      
// 0000000   0000000    000   000  000      000      
//      000  000  000   000   000  000      000      
// 0000000   000   000   0000000   0000000  0000000  

void skull()
{
    skull_sdf.pos.x = abs(skull_sdf.pos.x);
    skull_sdf.pos.y -= 0.15;
    skull_sdf.pos *= alignMatrix(vx, normalize(vec3(0.0,1.0,-0.5)));

    float d, h;
    
    d = sdEllipsoid(vy, vec3(5.5,5.5,5.0)); // frontal
    
    if (d > 15.0) {
        skull_sdf.dist = min(skull_sdf.dist, d);
        return;
    }
    
    d = opUnion(d, sdSphere( 2.0*vy -2.0*vz, 6.0), 1.0);            // parietal
    d = opDiff (d, sdPlane (-vy, vy), 1.5);                         // cranial cutoff
    d = opUnion(d, sdCone  ( 4.1*vz -2.5*vy, 2.5, 1.8, 3.5), 0.5);  // jaw
    d = opDiff (d, sdCone  ( 4.1*vz -2.5*vy, 1.6, 0.6, 3.5), 0.5);  // jaw hole
    d = opDiff (d, sdCone  ( 5.8*vz -0.1*vy, 1.0, 0.5, 1.5), 0.3);  // nose
    d = opDiff (d, sdPlane (-2.5*vy, vy), 0.5);                     // jaw cutoff
    d = opDiff (d, sdSphere( 2.7*vx +3.0*vy +3.6*vz, 2.0), 0.5);    // eye holes
    
    d = opDiff(d, sdBox(7.2*vx+3.5*vy-1.2*vz, normalize(vec3(1,-0.2,0.4)), vy, vec3(2.0,3.0,3.0), 1.0), 1.0);
    
    h = sdCapsule(-2.5*vy-1.5*vz, -2.5*vy-0.2*vz, 3.6);
    h = opUnion(h, sdCapsule(vy-2.0*vz, vy-0.5*vz, 3.6));
    d = opDiff(d, h, 1.0);
    
    sdMat(0, d);
    
    sdMat(1, sdBox(0.47*vx-2.8*vy+6.1*vz, normalize(vec3(1,0,-0.2)), vy, vec3(0.50,0.70,0.3), 0.3));
    sdMat(1, sdBox(1.29*vx-2.8*vy+5.7*vz, normalize(vec3(1,0,-0.8)), vy, vec3(0.47,0.65,0.3), 0.3));
    sdMat(1, sdBox(1.80*vx-2.8*vy+5.0*vz, normalize(vec3(0.4,0,-1)), vy, vec3(0.47,0.65,0.3), 0.3));
    sdMat(1, sdBox(2.00*vx-2.8*vy+4.1*vz, normalize(vec3(0,  0,-1)), vy, vec3(0.47,0.65,0.3), 0.3));
}

// 0000000     0000000   000   000  00000000  
// 000   000  000   000  0000  000  000       
// 0000000    000   000  000 0 000  0000000   
// 000   000  000   000  000  0000  000       
// 0000000     0000000   000   000  00000000  

void bone()
{
    skull_sdf.pos.x = abs(skull_sdf.pos.x);
    
    float d;
    vec3 ctr = 5.0*vz - 1.8*vy;
    vec3 rgt =  7.0*vx +ctr+3.0*vz;
    d = sdCapsule(ctr, rgt, 0.9);
    d = opUnion(d, sdSphere(rgt+vz, 1.7), 0.5);
    d = opUnion(d, sdSphere(rgt-vz-vx, 1.5), 0.5);
    
    rgt -= 6.0*vz;
    rgt += (rgt-ctr)*0.3;
    d = min(d, sdCapsule(ctr, rgt, 0.9));
    d = opUnion(d, sdSphere(rgt-vz, 1.7), 0.5);
    d = opUnion(d, sdSphere(rgt+vz-vx, 1.5), 0.5);
    
    sdMat(2, d);
}

// 00     00   0000000   00000000   
// 000   000  000   000  000   000  
// 000000000  000000000  00000000   
// 000 0 000  000   000  000        
// 000   000  000   000  000        

void sdStart(vec3 p)
{
    skull_sdf.dist  = 10.0;
    skull_sdf.pos   = p;
}

float map(vec3 p)
{
    sdStart(p);
    
    bone();
    skull();
    
    return skull_sdf.dist;
}

float sdf(vec3 p){
	//p *= RotMat(vec3(0.,1.,0.), -pi/4.0);
	p += vec3(0.0,0.0,0.15);
    const float scale = 0.075;
    p *= (1.0 / scale);
    //p.z -= 3.0;
    return map(p) * scale;
}

#endif 
