/*
Copyright 2019 Florian Berger @flockaroo
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wdfcz2
*/

/******************************************************************************
 This work is a derivative of work by Florian Berger used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

const vec3 BodySize=vec3(1.8,4.14,1.0);

////////////////////////
//// quaternions, sdf's, helper funcs
////////////////////////

#define PI  3.14159265359
#define PI2 6.28318530718
#define PIH 1.57079632679

#define ROTM(ang) mat2(cos(ang-vec2(0,PIH)),-sin(ang-vec2(0,PIH)))

mat3 RotMat(vec3 axis, float angle) {
  // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,
              oc * axis.z * axis.x + axis.y * s,
              oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c,
              oc * axis.y * axis.z - axis.x * s,
              oc * axis.z * axis.x - axis.y * s,
              oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}


vec3 rotZ(float ang,vec3 v) { return vec3(ROTM(ang)*v.xy,v.z); }

vec2 uvSmooth(vec2 uv,vec2 res)
{
    // no interpolation
    //return uv;
    // sinus interpolation
    return uv+1.*sin(uv*res*PI2)/(res*PI2);
    // iq's polynomial interpolation
    vec2 f = fract(uv*res);
    return (uv*res+.5-f+3.*f*f-2.0*f*f*f)/res;
}

vec4 inverseQuat(vec4 q)
{
    //return vec4(-q.xyz,q.w)/length(q);
    // if already normalized this is enough
    return vec4(-q.xyz,q.w);
}

vec4 multQuat(vec4 a, vec4 b)
{
    return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}

vec3 transformVecByQuat( vec3 v, vec4 q )
{
    return (v + 2.0 * cross( q.xyz, cross( q.xyz, v ) + q.w*v ));
}

vec4 angVec2Quat(vec3 ang)
{
    float lang=length(ang);
    return vec4(ang/lang,1) * sin(vec2(lang*.5)+vec2(0,PI2*.25)).xxxy;
}

vec4 axAng2Quat(vec3 ax, float ang)
{
    return vec4(normalize(ax),1)*sin(vec2(ang*.5)+vec2(0,PI2*.25)).xxxy;
}

// iq's sdf primitives
float distBox( vec3 p, vec3 halfSize)
{
    vec3 q = abs(p) - halfSize;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float distBoxR( vec3 p, vec3 halfSize, float r) { return distBox( p, halfSize-r ) - r ; }

float distCyl( vec3 p, float r, float h )
{
  vec2 d = vec2( length(p.xy)-r, abs(p.z) - h*.5 );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float distCylR( vec3 p, float r, float h, float R )
{
  vec2 d = vec2( length(p.xy)-(r-R), abs(p.z) - (h*.5-R) );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0))-R;
}

float distTorus(vec3 p, float R, float r)
{
    return length(p-vec3(normalize(p.xy),0)*R)-r;
}

// iq's exponantial smooth-min func
float smin( float a, float b, float k )
{
    k=3./k;
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

// iq's polynomial smooth-min func
float smin_( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// flatness: // 0->sphere, 100-> nearly cylindric
float distTire(vec3 p, float r, float w, float h, float flatness)
{
    float l=length(p.xy);
    //p=abs(p);
    float d=1000.;
    // outer sphere
    float rfl=r*(1.+flatness);
    d=min(d,length(vec2(l+rfl-r,p.z))-rfl);
    float rz=-(rfl-r)+sqrt(rfl*rfl-p.z*p.z);
    //d=min(d,l-rz);
    float ang = atan(p.x,p.y);
    //p.z+=cos(ang*100.)*w*.01*smoothstep(.87*r,1.*r,l);
    // main torus
    d=max(d,length(vec2(l-r+h*.5,p.z))-w*.5);
    //d=max(d,-l+r*.61);
    float w_l=sqrt(w*w-h*h); // w_laufflaeche
    float dz=.122*w_l;
    float zfr=mod(p.z,dz);
    float z=p.z-zfr+dz*.5;
    // rillen
    d=max(d,-length(vec2(l-rz,p.z-z))+dz*.2);
    // rim radius
    d=max(d,-(l-(r-h)));
    return d;
}

float distRim(vec3 p, float r, float w, float sh)  // outer rim radius, rim width;
{
    vec3 p0=p;
    p.z=abs(p.z);

    float d=1000.;
    float dmain=distCyl(p,r+sh-.005,w-.005)-.005;
    d=min(d,dmain);

    //d=max(d,-(distCyl(p-vec3(0,0,w*.5),r-sh*.5-.005,w*.05-.005)-.005));
    float d2=length(p-vec3(0,0,+w*.03+r*1.5))-r*1.5;
    d2=-smin_(-d2,-(distCyl(p-vec3(0,0,w*.5),r-sh*1.2-.005,w*1.-.005)-.005),.005);
    d=-smin(-d,d2,.01);

    float mang,ang;
    float ang0 = atan(p.y,p.x);
    float dang;
#ifdef NEW_MODEL
    dang=PI2/5.;
#else
    dang=PI2/15.;
#endif
    mang=mod(ang0,dang);
    ang=ang0-mang+dang*.5;
    // rim holes
#ifdef NEW_MODEL
    d=max(d,-distCyl(p-vec3(r*.53*cos(ang-vec2(0,PIH)),0.),.17*r,w*1.3));
#else
    d=max(d,-distBox(rotZ(-ang,p-vec3(r*.64*cos(ang-vec2(0,PIH)),0.)),vec3(.17*r,.17*r,w*1.3)*.52));
#endif
    dang=PI2/5.;
    mang=mod(ang0+dang*.5,dang);
    ang=ang0-mang+dang*.5;
    // screw holes
    d2=distCyl(p-vec3(r*.28*cos(ang-vec2(0,PIH)),w*.05),.016,w*.19);
    d=max(d,-d2);
    // screws
    d=min(d, d2+.005);

    // axle
    d=min(d, distCyl(p,.03-.01,w*.25-.01)-.01);
    return d;
}

float distWheelDim(vec3 p, float w_mm, float h_perc, float rimD_inch, float shoulder_mm, float flatness)
{
    float w=w_mm*.001;
    float h=w*h_perc/100.;
    float d=10000.,d2;
    float rrim=rimD_inch*.5*.0254;
    d2=distTire(p, rrim+h, w, h, flatness );
    d=min(d,d2);
    float rimw=sqrt(w*w-h*h)+shoulder_mm*.001;
    d2=distRim(p, rrim, rimw, shoulder_mm*.001 );
    d=min(d,d2);
    return d;
}


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

float distCar(vec3 p)
{
    vec3 p1,p2;
    p.x=abs(p.x);
    vec3 p0=p;
    // torus
    float d=10000.,d2;
    p=p0-vec3(-p.y*.01,0,0);
    vec3 p01=p;
    float yfall=min((p.y+0.0)*abs(p.y+0.0),0.);
    float yfall2=(p.y>.0?2.5:7.)*min((-abs(p.y)+1.2)*abs(-abs(p.y)+1.2),0.);
    yfall=mix(yfall,yfall2,step(0.,-p.z));
    //yfall=0.;
    // ----------- 1 ------------------ side phase
    d2=dot(p-.51*BodySize*vec3(.5,0,1.+.15*yfall)-(.2+.2*p.y)*max(0.,p.x-.92+p.y*.03)*vec3(0,0,1),normalize(vec3(.8,0,1.-.9*yfall)));
    d=min(d,d2);
    
    // ----------- 3 ------------------
    vec3 n=normalize(vec3(0,1,2.5));
    float dpx=max(p.x*1.-1.,-.5);
    float dpy=max(p.y-.78+.65*dpx,0.);
    p2=p-.05*(1.-dpx*5.-dpx*dpx*10.)*(1.-exp(-dpy/.2)-dpy*.8);
    //vec3 p2=p-.05*(1.-dpx*5.-dpx*dpx*10.)*min(1.-dpy*.2,1.);
    // ----------- 2 ------------------ front cut
    d2=dot(p2-.5*BodySize*vec3(0,1,1)-vec3(0,0,-.75),normalize(vec3(0,1,2.5)));
    d=-smin_(-d,-d2,.06*exp(-(p.y-1.1)*(p.y-1.1)*3.));
    //d=-smin(-d,-d2,.13*clamp(1.-(p.y-1.)*(p.y-1.)*1.2,0.,1.));
    //d=-min(-d,-d2);
    
    // -------------------------------- main box ---- done after cuts to get sharp contour line on sides (no smin there)
    d2=distBoxR(p+vec3(min(+.35*p.z*p.z,.1),0,0),
                vec3(BodySize.xz,100).xzy*.5*vec3(exp(-(step(0.,p.y)*2.+2.)*p.y*p.y*p.y*p.y/500.),1,1.+.15*yfall),
                max(.02,-1.*p.z-.07*p.y));
    d=max(d,d2);
    
    // ----------- 4 ------------------ engine cover
    p-=vec3(0,-1.65,.48);
    vec3 bs=vec3(BodySize.x*.25*1.1-p.y*.17+p.z*.4,1,.3);
    d2=distBoxR(p+vec3(0,0,-p.y*.14),bs,.02);
    d=max(d,-d2);
    float pry=clamp(floor(p.y/.22+.5),1.,4.)*.22;
    d2=distBoxR(p+vec3(0,-pry,.01-p.y*.14),bs-vec3(.06,.92,0),.02);
    d=max(d,-d2);

    d2=abs(p0.y)-BodySize.y*.5;
    d2+=.005*exp(-(length(vec2(max(d+.03,0.),d2)))/.0025);
    d=-smin_(-d,-d2,.01);
    
    d2=distBox(p01-vec3(0,-1.1,.3),vec3(.47,.5,.5));
    d+=.004*exp(-abs(d2)/.004);

    // ------------------------------- side air hole
    p=p0-vec3(.9,-.35,.04);
    float sn=(.6-.4*sin(p.y*6.));
    d2=distBox(p,vec3(.2*sn,.5,.23*sn)*.5-.02)-.02;
    d=max(d,-d2);

    // ------------------------------- upper air hole
    p=p01-vec3(.67,-.627,.35);
    d2=distBoxR(p,vec3(.32,.45,.25)*.5,.02-p.y*.15);
    //d=max(d,-d2);
    float d3=dot(p,normalize(vec3(.58,-.5,1.)));
    float lw=.028+p.x*.028;
    d3=(fract(d3/lw)-.5)*lw;
    d3=abs(d3)-lw*.3;
    d3=max(d2,-d3);
    //d2=max(d2,-d3);
    d3=max(d3,(d+.01-p.y*.045));
    d=max(d,-d2);
    d=min(d,d3);

    // make hollow (6cm thick)
    //d=abs(d+.03)-.03;
    
    // ------------------------------ door
    //   --- front win border
    d2=dot(p01-vec3(.475,.19,0),normalize(vec3(2.,-1,0)));
    //   --- inner border
    d2=min(d2, dot(p01-vec3(.475,.19,0),normalize(vec3(1,0,0))) );
    d3 = d2;
    p=p01-vec3(.475,-.4,0);
    float s=step(0.,-(p0.z-.2))*((p0.z-.2)*(p0.z-.2)-.25*(p0.z-.2));
    p.y=p.y-s;
    //   --- front door border
    float dr=dot(p,normalize(vec3(0,1,0)));
    d2=min(d2, dr );
    p.y=p.y+2.*s-1.35;
    float d4=10000.;
    //   --- rear door border
    d4=min(d4, dot(p,normalize(vec3(0,-1,0))) );
    //   --- floor door border
    d4=min( d4, dot(p01-vec3(0,0,-.22),normalize(vec3(0,0,1))) );
    //d+=.005*exp2(-length(vec2(d2-.0,d))/.0025);
    d2=min(d2,d4);
    d+=.003*exp2(-abs(d2)/.003);
    
    // ------------------------------ side window
    d4=min(d4, dot(p01-vec3(.87,0,0),normalize(vec3(-1,0,0))) );
    d2=min(d2,d4);
    d3-=.22;
    //d3=min(d3,min(d4,dr)-.04);
    //d3-=.22;
    d+=.005*exp2(-length(vec2(min(d2-.04,0.),d))/.0025);
    if(d3<min(d4,dr)-.04)
    //d+=.003*exp2(-d3*d3/.003/.003);
    d=min(d,length(vec2(d3,d))-.003);

    // ------------------------------- front lights
    p=p0-vec3(.65,1.6,0);
    d2=distBox(p,vec3(.32-step(0.,p.x)*.25*p.y,.16,.2)*.5);
    //d=max(d,-sqrt(d*d+d2*d2)+.005);
    d+=.003*exp(-abs(d2)/.003);
    p=p0-vec3(.63,1.85,0);
    d2=distBox(p,vec3(.29-step(0.,p.x)*.45*p.y,.16,.34)*.5);
    d=max(d,-d2);

    // ------------------------------ wheels
    p1=BodySize*.5*vec3(1, .59,-.65);
    p2=BodySize*.5*vec3(1,-.63,-.65);
    d=max(d,-distCylR((p0-p1).yzx,.35,.85,.05));
    //d=max(d,-distCylR((p0-p2).yzx,.35,.8,.05));
    d=max(d,-distBoxR(rotZ(0.4,(p0-p2).yzx),vec3(.37,.28,.45)+.015,.2-(p0-p2).y*.2));
    //d=min(d,distCylR((p0-p1-vec3(-.18,0,.04)).yzx,.31,.27,.08));
    //d=min(d,distCylR((p0-p2-vec3(-.145,0,.04)).yzx,.31,.27,.08));
    //return distWheelDim(pos,345.,35.,15.,10.,2.7);

    //d=min(d,distWheelDim((p0-p2-vec3(-.13,0,.04)).yzx,215.,70.,14.,20.,1.));
    //d=min(d,distWheelDim((p0-p1-vec3(-.16,0,.04)).yzx,205.,70.,14.,20.,1.));

#ifndef NEW_MODEL    
    float wheelDimRear [] = float[](215.,70.,14.,15.,1.);
    float wheelDimFront[] = float[](205.,70.,14.,15.,1.);
    vec3 pfront = p1+vec3(-.16,0,.04);
    vec3 prear  = p2+vec3(-.13,0,.04);
#else
    float wheelDimRear [] = float[](345.,35.,15.,12.,2.7);
    float wheelDimFront[] = float[](205.,50.,15.,12.,1.);
    vec3 pfront = p1+vec3(-.15,0,.04);
    vec3 prear  = p2+vec3(-.19,0,.04);
#endif
    
    bool front = p0.y>0.;
    p=p0-(front?pfront:prear);
    d=min(d,
        distWheelDim(p.yzx,
                     front?wheelDimFront[0]:wheelDimRear[0],
                     front?wheelDimFront[1]:wheelDimRear[1],
                     front?wheelDimFront[2]:wheelDimRear[2],
                     front?wheelDimFront[3]:wheelDimRear[3],
                     front?wheelDimFront[4]:wheelDimRear[4])
         );
    return d;
}

float sdf(vec3 p) {
  const float scale = 0.4;
  p *= 1. / scale;
  mat3 trans = RotMat(vec3(0., 1., 0.), -pi) * RotMat(vec3(1., 0., 0.), pi / 2.);
  return distCar(p * trans) * scale;
}
