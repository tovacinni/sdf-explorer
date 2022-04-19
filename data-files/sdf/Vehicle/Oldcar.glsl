/*
Copyright 2019 Florian Berger @flockaroo
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/3ttXzj
*/

/******************************************************************************
 This work is a derivative of work by Florian Berger used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef oldcar_glsl
#define oldcar_glsl

#define PI2 6.283185
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

vec4 inverseQuat(vec4 q)
{
    //return vec4(-q.xyz,q.w)/length(q);
    // if already normalized this is enough
    return vec4(-q.xyz,q.w);
}


vec3 transformVecByQuat( vec3 v, vec4 q )
{
    return (v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v ));
}

vec4 axAng2Quat(vec3 ax, float ang)
{
    return vec4(normalize(ax),1)*sin(vec2(ang*.5)+vec2(0,PI2*.25)).xxxy;
}

// iq's sdOldcarf primitives

float sdOldcarRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - (b-r);
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdOldcarBox( vec3 p, vec3 b)
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdOldcarRoundRect( vec2 p, vec2 b, float r )
{
  vec2 q = abs(p) - (b-r);
  return length(max(q,0.0)) + min(max(q.x,q.y),0.0) - r;
}

vec2 sdOldcarRoundRect2( vec4 p, vec4 b, vec2 r )
{
  vec4 q = abs(p) - (b-r.xxyy);
  vec4 qp=max(q,0.0);
  return sqrt(qp.xz*qp.xz+qp.yw*qp.yw) + min(max(q.xz,q.yw),vec2(0)) - r;
}

float sdOldcarHalfRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - (b-r);
  return max((length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r),-p.z);
}

float sdOldcarRoundedCylinder( vec3 p, float R, float r, float h )
{
  vec2 d = vec2( length(p.xz)-R, abs(p.y) - h*.5 );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - r;
}

// iq's capsule
float sdOldcarLine( vec3 p, vec3 a, vec3 b)
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h );
}

float distTorus(vec3 p, float R, float r)
{
    return length(p-vec3(normalize(p.xy),0)*R)-r;
}

float sdOldcarCone( vec3 p, vec2 c )
{
  // c is the sin/cos of the angle
  float q = length(p.xy);
  return dot(c,vec2(q,p.z));
}

// iq's exponantial smooth-min func
float sminOldCar( float a, float b, float k )
{
    k=3./k;
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// iq's polynomial smooth-min func
float sminOldCar_( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
#if 0
bool intersectBox(vec3 p, vec3 dir, vec3 size)
{
    //vec3 n=cross(cross(dir,p),dir);
    //return length(p-dot(p,n)*n/dot(n,n))<size.y;

    //return true;
    
    size*=.5;
    float tmin, tmax, tymin, tymax, tzmin, tzmax; 
    
    vec3 s=sign(dir);
    vec3 invdir=1./dir;

    tmin  = (-size.x*s.x - p.x) * invdir.x; 
    tmax  = ( size.x*s.x - p.x) * invdir.x; 
    tymin = (-size.y*s.y - p.y) * invdir.y; 
    tymax = ( size.y*s.y - p.y) * invdir.y; 
 
    if ((tmin > tymax) || (tymin > tmax)) return false; 
    if (tymin > tmin) tmin = tymin; 
    if (tymax < tmax) tmax = tymax; 
 
    tzmin = (-size.z*s.z - p.z) * invdir.z; 
    tzmax = ( size.z*s.z - p.z) * invdir.z; 
 
    if ((tmin > tzmax) || (tzmin > tmax)) return false; 
    if (tzmin > tmin) tmin = tzmin; 
    if (tzmax < tmax) tmax = tzmax; 
 
    return true; 
}
#endif
bool intersectBox(vec3 p, vec3 dir, vec3 size)
{
    size*=.5*sign(dir);

    vec3 vmin = (-size-p)/dir;
    vec3 vmax = ( size-p)/dir;
    
    float tmin=vmin.x, tmax=vmax.x;
    
    if ((tmin > vmax.y) || (vmin.y > tmax)) return false; 
    tmin=max(tmin,vmin.y);
    tmax=min(tmax,vmax.y);
 
    if ((tmin > vmax.z) || (vmin.z > tmax)) return false; 
    tmin=max(tmin,vmin.z);
    tmax=min(tmax,vmax.z);
 
    return true; 
}

vec2 ROT(float ang, vec2 v) 
{ 
    vec2 cs=sin(vec2(1.6,0)+ang); 
    return mat2(cs,cs.yx*vec2(-1,1))*v;
}

float bigZ(vec2 p)
{
    vec2 p0=p;
    
    p=ROT(-.05,p);
    
    p+=vec2(0,.7);
    //float falloff=exp(-dot(p,p));
    float falloff=1./(1.+dot(p,p)*2.);
    p=ROT(-PI2*.2*falloff*p.y,p-vec2(0,.7));   // locally rotate around x by 180 degrees

    p.x+=.7*p.y;
    
    //p.x-=p.y;
    p=-sign(p.y+p.x)*p;
    
    float d=abs(max(-p.y-.5,p.x));
    d-=.04+.1/(1.+dot(p0,p0)*3.)+.03*min(p0.x,0.);
    return d;
}

float fermi(float x)
{
    return 1./(1.+exp(-x));
}

#define RUMPFW 1.3
#define ALLW (RUMPFW*1.3)

#define WheelDistF (ALLW*.78)
#define WheelDistR (ALLW*.96)
#define WheelPosFR (vec3(-WheelDistF*.5,-1.43,-.33)*2.)
#define WheelPosRL (vec3( WheelDistR*.5, 1.23,-.35)*2.)
#define WheelPosFL (vec3( WheelDistF*.5,-1.43,-.33)*2.)
#define WheelPosRR (vec3(-WheelDistR*.5, 1.23,-.35)*2.)

vec4 wheelOffs=vec4(0);
#define WheelOffsRL wheelOffs.x
#define WheelOffsRR wheelOffs.y
#define WheelOffsFL wheelOffs.z
#define WheelOffsFR wheelOffs.w

#define WheelRadiusF .62
#define WheelRadiusR .7

#define SHADOW
#define SCRATCHES
#define RENDER_GLASS

//#define RND_SC (256./64.)
#define RND_SC 1.

#define BG 0.
#define CARBODY 1.
#define GUMMI 2.
#define RIM 3.
#define FLOOR 4.
#define CHROME 5.
#define INTERIOR 6.
#define GLASS 7.
#define CHASSIS 8.
#define DBG_GREEN 9.
#define DBG_RED 10.

#define SET_PREV_MAT(x) if(abs(d-d_mat)>.0001) mat=(x); d_mat=d;

struct Material{
    vec3 col;
    float refl;
    float scratchy;
    vec2  scratchScale;
};

//#define MAT_CARBODY    Material(vec3(.8, .05, .1),    -1.,   0.6, vec2(1,.01))
#define MAT_BG         Material(vec3(-1,-1,-1),       -1.,   0.0, vec2(1,.01))
#define MAT_CARBODY    Material(vec3(.5),    1.,   1., vec2(1,.03))
#define MAT_GUMMI      Material(vec3(.15,.15,.15),    -0.35, 1.0, vec2(1,.1)*.3)
#define MAT_RIM        Material(vec3(.3),          -1.,   0.6, vec2(1,.01))
#define MAT_FLOOR      Material(vec3(.36,.35,.34)*1.2,            -0.2, 0.0, vec2(1,.01))
#define MAT_CHROME     Material(vec3(.8),              1.,   0.1, vec2(1,.1))
#define MAT_INTERIOR   Material(vec3(.9,.7,.5)*.3,    -0.0,  0.0, vec2(1,.01))
#define MAT_OLDGLASS      Material(vec3(1),              -1.,   0.6, vec2(1,.01))
#define MAT_CHASSIS    Material(vec3(.45),              1.,  1.0, vec2(1,.01)*.5)
#define MAT_DBG_GREEN  Material(vec3(0,1,0), -1.,  0.0, vec2(1,.01))
#define MAT_DBG_RED    Material(vec3(1,0,0), -1.,  0.0, vec2(1,.01))

#define USE_MTL_ARRAY 
#ifdef USE_MTL_ARRAY
const Material mat[11] = Material[] (
MAT_BG        ,
MAT_CARBODY   ,
MAT_GUMMI     ,
MAT_RIM       ,
MAT_FLOOR     ,
MAT_CHROME    ,
MAT_INTERIOR  ,
MAT_OLDGLASS     ,
MAT_CHASSIS   ,
MAT_DBG_GREEN ,
MAT_DBG_RED
);
#endif

#define DESERT FLOOR
#define TIRE GUMMI
#define GRILL CHROME

bool enable_glass=true;

#define FloorZ -.66
//#define HomePos vec3(0,0,-FloorZ*1.5)
//#define CamDist0 18.

float distTire(vec3 p, float r)
{
    p=abs(p);
    float d=1000.;
    d=min(d,length(p)-r);
    float ang = atan(p.z,p.y);
    float l=length(p.zy);
    p.x+=cos(ang*100.)*.005*smoothstep(.87*r,1.*r,l);
    d=max(d,distTorus(p.yzx+vec3(0,0,.03),r*.78,r*.28));
    d=max(d,-l+r*.61);
    float dx=.04;
    float xfr=mod(p.x,dx);
    float x=p.x-xfr+dx*.5;
    d=max(d,-distTorus(p.yzx-vec3(0,0,x),sqrt(r*r-x*x),.01));
    return d;
}


float distRim(vec3 p, float r)
{
    r*=.6;
    vec3 p0=p;
    p.x=abs(p.x);
    //p.yz=(p.y>p.z)?p.zy:p.yz; // only first 1/8 segment
    p=p.zxy;
    float d=1000.;
    d=min(d,sdOldcarRoundedCylinder(p,r,.01,.6*r));
    p-=vec3(0,.6*r,0);
    d=-sminOldCar(-d,sdOldcarRoundedCylinder(p,.97*r,.01,.6*r),.015);
    d=-sminOldCar(-d,sdOldcarRoundedCylinder(p,.89*r,.01,.8*r),.015);
    float d_i=sdOldcarRoundedCylinder(p,.77*r,.01,1.9*r);
    d=-sminOldCar(-d,d_i,.015);
    
    float d2=length(p0-vec3(-r*.6,0,0))-r*1.05;
    d2=max(d2,d_i);
    d2=-sminOldCar(-d2,sdOldcarRoundedCylinder(p,.4*r,.01,.8*r),.1);
    d2=abs(d2)-.005;
    d2=max(d2,-p0.x);

    float mang,ang;
    float ang0 = atan(p.z,p.x);
    float dang=PI2/5.;
    mang=mod(ang0,dang);
    ang=ang0-mang+dang*.5;

    d2=-sminOldCar(-d2,(length(p.xz-.95*r*cos(ang-vec2(0,1.57)))-.25*r),.01);
    d=min(d,d2);
    dang=PI2/5.;
    mang=mod(ang0,dang);
    ang=ang0-mang+dang*.5;
    d=min(d,max(abs(p.y+.6*r)-.22*r,(length(p.xz-.3*r*cos(ang-vec2(0,1.57)))-.05*r)));
    d=min(d,sdOldcarRoundedCylinder(p-vec3(0,-.23,0),.1*r,.01,.25));
    float l=length(p0.zx);
    d=min(d,sdOldcarRoundedCylinder(p0.zxy-vec3(0,-.06,0),.7*r,.02,.05-.015*fermi((length(p.xz)-.6*r)/.003)));
    return d;
}

const vec3 bbpos=vec3(0,-.06,.07);
const vec3 bbsize=vec3(ALLW*1.12,3.63,1.5);
const vec3 bbpos1=vec3(0,.04,-.231);
const vec3 bbsize1=vec3(ALLW*1.08,3.68,1.23);
const vec3 bbpos2=vec3(0,.23,.33);
const vec3 bbsize2=vec3(ALLW*.83,1.25,.7);

float rille2(float d, float w)
{ 
    return w*exp2(-d*d*2./w/w);
}
float rille(float d, float w)
{
    return w*exp2(-abs(d)*1.44/w);
}

const float SteerAng = 0.;
const vec4 WheelRot=vec4(0);

#define PF WheelPosFL
#define PR WheelPosRL


vec2 distCar(vec3 p)
{
    //p.xy*=-1.;
    vec3 p0rot=p;
    p=transformVecByQuat(p,axAng2Quat(vec3(1,0,0),-.023));
    float d=1000., d_mat=1001., mat=-1.;
    SET_PREV_MAT(BG);
    p*=2.;
    if(p.x<0.) p.x=-p.x;
    vec3 p0=p+vec3(0,0,.13);
//#define SIMPLE_CAR
#ifndef SIMPLE_CAR
    //d=min(d,length(p)-.5);
    p=p0+vec3(0,.1,0);
    float drumpf=sdOldcarRoundBox( p, vec3(RUMPFW+p.y*.15-p.y*p.y*.04+p.z*p.y*.03, 
                                 3.2-p.z*.3+p.z*p.z*.1 - step(0.,-p.y)*p.x*.3-step(0.,p.y)*.4*p.z, 
                                 .8+p.y*.02-p.x*p.x*.05*(1.+.01*(p.y*p.y*p.y*p.y))),
                             max(p.y*.04,mix(.25+p.y*.05,.07,-p.z*1.5+.5)))*.7;
    p=p0-vec3(0,.5,.7);
    float dcabin = sdOldcarRoundBox( p, vec3(RUMPFW*1.04+p.y*.07-p.y*p.y*.08+p.z*.0, 
                                       1.2-p.z*(.7-.4*step(0.,p.y)),
                                       .7+p.y*.07-p.x*p.x*.05-p.y*p.y*.05),
                               .33+.15*p.y )*.7;
    d=min(d,dcabin);
    // rear front screen
    p=p0-vec3(0,.4,.88+.10-.06*p.x*p.x);
    //float dfrontscr=sdOldcarRoundBox( p, vec3(RUMPFW*.4-step(0.,p.y)*.2,2.,.1-step(0.,p.y)*.03)*2., .1 )*.7;
    // only 2d needed - not sure if rect is faster - maybe some compilers can optimize something out...
    float sy=step(0.,p.y);
    float dfrontscr=sdOldcarRoundRect( p.xz-vec2(0,-.12+sy*.1), vec2(RUMPFW*.4-sy*.2,.12-step(0.,p.y)*.07)*2., .14-sy*.04 )*.7;
    dfrontscr=max(dfrontscr,-(drumpf-.07));
    d=-sminOldCar(-d,dfrontscr,.03);
    // side screens
    p=p0-vec3(0,.23,.91);
    vec3 sidebox=vec3(2.,.35-(p.z+.3)*(.1+step(0.,p.z+.3)*.1),.065+p.y*.023-.05*p.y*p.y*step(0.,p.z))*2.;
#if 1
    float dsidescr=sdOldcarRoundRect( p.yz-vec2(.1*p.z,.015*p.y), sidebox.yz, .1+.07*p.y )*.7;
    float ddoor   =sdOldcarRoundRect( p.yz-vec2(.1*p.z,.015*p.y)+vec2(0,.79), sidebox.yz+vec2(0,.79), .08+.07*p.y )*.7;
#else
    // not sure if even making 2 rects at once is really faster...
    vec2 dssdOldcaroor=sdOldcarRoundRect2( (p.yz-vec2(.1*p.z,.015*p.y)).xyxy+vec4(0,0,0,.59), sidebox.yzyz+vec4(0,0,0,.59), vec2(.13+.04*p.y) )*.7;
    float dsidescr=dssdOldcaroor.x;
    float ddoor=dssdOldcaroor.y;
#endif
    ddoor-=.07;
    float dhood1 =  dot(p0-vec3(0,-3.22,0),vec3(.28,-1,.28));
    float dhood2 =  -dot(p0-vec3(0,-1.35,0),vec3(.28,-1,.28));
    float dhood=max(dhood1,dhood2);
    d=-sminOldCar(-d,dsidescr,.05);
    d-=clamp((abs(dsidescr-.03)-.016)*.2,-0.02,0.);
    p=p0;
    p-=vec3(0,0,-.77);
    float dz1=.5*(cos(p.x*4./ALLW)-1.)*(cos(p.y*1.5-2.-step(2.86,-p.y)*.8*(p.y+2.86)*(p.y+2.86))*.4+.4)*step(.766,-p.y);
    float dz2=.5*(cos(p.x*3.3/ALLW)-1.)*clamp((cos(p.y*.6-1.5)*2.5-2.)*1.7,0.,1.);
    p.z+=dz1+dz2;
    p-=vec3(0,-.07,0);
    
    #if 1
    float dfender = sdOldcarRoundBox( p-vec3(0,0,-.3), vec3(ALLW+p.y*.05,
                                3.5-.1*cos(p.x*p.x*3.3/ALLW*(.85+.15*step(0.,-p.y)))*(.3+.7*step(0.,-p.y)),.16+.3),
                                .16 )*.7;
    float ss=1.-smoothstep(-3.,-1.8,p.y);
    float fz0=p.z-dz1*(exp2(-ss*7.));
    dfender=min(dfender,(sqrt(dfender*dfender+fz0*fz0)-.01)*.7);
    dfender=max(dfender,-(fz0)*.7);
    #endif
    
    SET_PREV_MAT(CARBODY);
    float dfloorline=p0.z+0.7-.5*(.5-.5*cos((p0.y*1.-p0.y*p0.y*.1)*step(0.,-p0.y)));
    ddoor=-sminOldCar(-ddoor,dfloorline-.06,clamp(.15-.1*p0.y,0.01,.3));
    dhood=-sminOldCar(-dhood,dfloorline-.08,clamp(.25+.05*p0.y,0.01,.3));
    drumpf-=max(-dfloorline*.5-1.3*dfloorline*dfloorline,0.)*5.*clamp(((-p0.y-1.8)-.9*(-p0.y-1.8)*(-p0.y-1.8))*abs(-p0.y-1.8),0.,11.);
    drumpf+=rille(dhood,.005);

    dfloorline=sminOldCar(length((p0-PR-vec3(0,0,.15)).zy)-.75,dfloorline,.4);
    drumpf-=.5*rille2(dfloorline,.03)*smoothstep(-.05,.05,p0.y+3.1);
    
    //side stripe
    p=p0+vec3(0,.1,0);
    drumpf-=.6*rille2(p.z-.4+.03*p.y-.1*p.x,.02)*(1.-smoothstep(2.4,2.6,abs(p0.y+.3)));
    float dBigZ=bigZ((p.yz-vec2(.7,0))*vec2(-1.5,2.3)*1.3)*.085*(1.-smoothstep(2.55,2.6,abs(p0.y+.35)))+abs(drumpf);
    
    // side lamelles
    vec3 pi = p0+vec3(0,-drumpf*2.-p0.z*.3,0)-vec3(0,-1.78,.3);
    drumpf = max(drumpf,-sdOldcarBox(pi-vec3(0,clamp(floor(pi.y/.12+.5)*.12,-1.08,0.34),0),vec3(2.,.047,.11))/1.4);
    
    drumpf+=rille(sdOldcarRoundRect(p0.yz-vec2(-2.05+(p0.z-.3)*.3,.3),vec2(.8,.15),.03),.005);
    
    drumpf=min(drumpf,dBigZ);
    
    d=sminOldCar(d,drumpf,.03);
    d+=rille(ddoor,.005);
    
    float z=p.z+.2;
    float dgrillhole=sdOldcarRoundBox( p-vec3(0,-3.,-.02), vec3(.18*.9*RUMPFW-step(0.,-z)*z*z*.58*RUMPFW,.5,.33)*2., .1 );
    d=-sminOldCar(-d,dgrillhole,.04);
    float f=smoothstep(-3.,0.,p.y);
    d=-sminOldCar(-d,-dgrillhole+.1+f*10.,.04);
    float newmtl=(dhood1<0.)?CARBODY:GRILL;
    SET_PREV_MAT(newmtl);
    d=min(d,step(0.,p.y)+length(vec2(dfrontscr-.01,dcabin+.01))-.015);
    SET_PREV_MAT(GUMMI);
    d=min(d,step(0.,p.y)+length(vec2(dfrontscr-.02,dcabin+.01))-.02);
    SET_PREV_MAT(GRILL);

    p=p0-vec3( 0, -3.26+.3*p.z+.35*p.x-.1*p.z*p.z, 0);
    p.x=mod(p.x+.005,.025)-.0125;
    d=min(d,max(dgrillhole,(length(p.xy)-.007)*.8));
    SET_PREV_MAT(GRILL);

    p=p0-vec3(0,.7,.87-.2);
    d=max(d,-dcabin-.06);
    SET_PREV_MAT(INTERIOR);
    
#ifdef RENDER_GLASS
    // window glass
    //if(enable_glass)
    {
        d=min(d,dcabin+.035+(enable_glass?0.:1000.));
        SET_PREV_MAT(GLASS);
    }
#endif

#else // SIMPLE_CAR
    d=min(d,sdOldcarBox(p,vec3(2,5,1.)*.5));
    SET_PREV_MAT(GRILL);
#endif // SIMPLE_CAR

    p0-=vec3(0,0,.13);
    
    vec3 pf=p0-PF;
    vec3 pr=p0-PR;
    
    // check tire only once
    //bool rear = (dot(pr,pr)<dot(pf,pf));
    float rear = step(0.,p0rot.y);
    float left = step(0.,p0rot.x);
    float leftSgn=sign(p0rot.x);
    p=mix(pf,pr,rear); float siz=mix(WheelRadiusF,WheelRadiusR,rear);
    
    float axOffs=0.;
    vec4 axQuat=vec4(0,0,0,1);

#if 1
    {
    // steering rotation of front wheels
    vec4 q=axAng2Quat(vec3(0,0,1),leftSgn*(1.-.1*leftSgn*sign(SteerAng))*SteerAng*(1.-rear));
#if 0
    p+=vec3(.07,0,0);
    p = (p + 2.0 * cross( q.xyz, cross( q.xyz, p ) + q.w*p ));
    p-=vec3(.07,0,0);
#else
    // the above is exactly this below... why is this not working... bug in nvidia pipeline?! or am i missing sth here??
    p=transformVecByQuat(p+vec3(.16,0,0),q)-vec3(.16,0,0);
#endif
    }
#endif

    d=min(d, distTire(p,siz));
    SET_PREV_MAT(TIRE);
    d=min(d, distRim(p,siz));
    SET_PREV_MAT(RIM);
    
    p=p0;
    float xx=p.x*p.x;
    p=p0-PF*vec3(0,1,1);
    // Frame
    d=min(d,sdOldcarRoundBox(p-vec3(.55+p.y*.1,0,.15)+vec3(0,0,1)*(p.y+.3)*(p.y+.3)*sign(-p.y)*.38, vec3(.06-p.y*p.y*.05,.7,.08-p.y*p.y*.05), .015 ));
    p=transformVecByQuat(p,axQuat);
    // Blattfeder (leaf spring)
    d=min(d,sdOldcarRoundBox(p+vec3(0,0,1)*p.x*p.x*.18*(1.-axOffs/.1), vec3(.8,.05,floor((.05-p.x*p.x*.035)/.008)*.008), .005 ));
    p.z-=axOffs;
    p.z+=.25*cos(p0.x*.8)-.15*fermi((p0.x-PF.x+.3)/.02);
    d=min(d,sdOldcarRoundBox(p, vec3(1.15,.02+.02*fermi((abs(p.z)-.03)/.002),.065-p.x*p.x*.015), .005 ));
    d=min(d,sdOldcarRoundedCylinder(p.xzy-vec3(+.9,0,0),.035,.005,.11));
    d=min(d,sdOldcarRoundedCylinder(p.xzy-vec3(+1.15,0,0),.035,.005,.11));
    d=max(d,-sdOldcarRoundedCylinder(p-vec3(floor(min(p.x,.8)/.1+.5)*.1,0,0),.03,.005,.11));
    d=min(d,sdOldcarLine(p0-vec3(0,PF.yz),transformVecByQuat(vec3(-.42+PF.x,.1,-.2),inverseQuat(axQuat))+vec3(0,0,axOffs),
                      vec3(-.22+PF.x,2.,-.25)
                  )-.02+p0.y*.015);
    
    SET_PREV_MAT(CHASSIS);
    
    #if 0
    p=p0-vec3(.37,-1.57,0.1)*2.;
    float d1=1000.;
    d1=min(d1, length(p)-.11*2.1);
    d1=-sminOldCar(-d1, (length(p+vec3(0,.35,0))-.17*2.1),.02);
    d=min(d,d1);
    SET_PREV_MAT(HEADLIGHTS);
    #endif
    
    return vec2(d*.5,mat);
}

float sdf(vec3 p){
	// from fish.glsl, change this and fix
    p += vec3(0.,0.05,0.);
	p *= RotMat(vec3(1.,0.,0.), pi/2.);
	const float scale = 0.5;
    p *= (1.0 / scale);
    return distCar(p).x * scale;
}
#endif
