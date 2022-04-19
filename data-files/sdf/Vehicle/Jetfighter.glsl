/*
Copyright 2017 Kim Berkeby @ingagard
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/MlscWX
*/

/******************************************************************************
 This work is a derivative of work by Kim Berkeby used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef jetfighter_glsl
#define jetfighter_glsl

#define PI acos(-1.)
float turn=0., pitch = 0. + pi, roll=0., rudderAngle = 0.;
float speed = 0.5;
vec3 checkPos=vec3(0.);
vec3 planePos=vec3(0.);

float winDist=10000.0;
float engineDist=10000.0;
float eFlameDist=10000.0;
float blackDist=10000.0;
float bombDist=10000.0;
float bombDist2=10000.0;
float missileDist=10000.0;
float frontWingDist=10000.0;
float rearWingDist=10000.0;
float topWingDist=10000.0;
vec2 missilesLaunched=vec2(0.);

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

float sgn(float x) 
{   
  return (x<0.)?-1.:1.;
}

struct RayHit
{
  bool hit;  
  vec3 hitPos;
  vec3 normal;
  float dist;
  float depth;

  float winDist;
  float engineDist;
  float eFlameDist;
  float blackDist;
  float bombDist;
  float bombDist2;
  float missileDist;
  float frontWingDist;
  float rearWingDist;
  float topWingDist;
};

float sdJetBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdJetTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x, p.y);
  return length(q)-t.y;
}

float sdJetCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa, ba)/dot(ba, ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdJetEllipsoid( vec3 p, vec3 r )
{
  return (length( p/r.xyz ) - 1.0) * r.y;
}

float sdJetConeSection( vec3 p, float h, float r1, float r2 )
{
  float d1 = -p.z - h;
  float q = p.z - h;
  float si = 0.5*(r1-r2)/h;
  float d2 = max( sqrt( dot(p.xy, p.xy)*(1.0-si*si)) + q*si - r2, q );
  return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float fCylinder(vec3 p, float r, float height) {
  float d = length(p.xy) - r;
  d = max(d, abs(p.z) - height);
  return d;
}
float fSphere(vec3 p, float r) {
  return length(p) - r;
}

float sdJetHexPrism( vec3 p, vec2 h )
{
  vec3 q = abs(p);
  return max(q.y-h.y, max((q.z*0.866025+q.x*0.5), q.x)-h.x);
}

float fOpPipe(float a, float b, float r) {
  return length(vec2(a, b)) - r;
}

vec2 pModPolar(vec2 p, float repetitions) {
  float angle = 2.*PI/repetitions;
  float a = atan(p.y, p.x) + angle/2.;
  float r = length(p);
  float c = floor(a/angle);
  a = mod(a, angle) - angle/2.;
  p = vec2(cos(a), sin(a))*r;
  if (abs(c) >= (repetitions/2.)) c = abs(c);
  return p;
}

float pModInterval1(inout float p, float size, float start, float stop) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p+halfsize, size) - halfsize;
  if (c > stop) {
    p += size*(c - stop);
    c = stop;
  }
  if (c <start) {
    p += size*(c - start);
    c = start;
  }
  return c;
}

float pMirror (inout float p, float dist) {
  float s = sgn(p);
  p = abs(p)-dist;
  return s;
}

mat2 r2(float r)
{
  float c=cos(r), s=sin(r);
  return mat2(c, s, -s, c);
}

#define r3(r) mat2(sin(vec4(-1, 0, 0, 1)*acos(0.)+r))
void pR(inout vec2 p, float a) 
{
  p*=r2(a);
}

float fOpUnionRound(float a, float b, float r) {
  vec2 u = max(vec2(r - a, r - b), vec2(0));
  return max(r, min (a, b)) - length(u);
}

float fOpIntersectionRound(float a, float b, float r) {
  vec2 u = max(vec2(r + a, r + b), vec2(0));
  return min(-r, max (a, b)) + length(u);
}

// limited by euler rotation. I wont get a good plane rotation without quaternions! :-(
vec3 TranslatePos(vec3 p, float _pitch, float _roll)
{
  pR(p.xy, _roll-PI);
  p.z+=5.;
  pR(p.zy, _pitch);
  p.z-=5.; 
  return p;
}

float MapEsmPod(vec3 p)
{
  float dist = fCylinder( p, 0.15, 1.0);   
  checkPos =  p- vec3(0, 0, -1.0);
  pModInterval1(checkPos.z, 2.0, .0, 1.0);
  return min(dist, sdJetEllipsoid(checkPos, vec3(0.15, 0.15, .5)));
}

float MapMissile(vec3 p)
{
  float d= fCylinder( p, 0.70, 1.7);
  if (d<1.0)
  {
    missileDist = min(missileDist, fCylinder( p, 0.12, 1.2));   
    missileDist =min(missileDist, sdJetEllipsoid( p- vec3(0, 0, 1.10), vec3(0.12, 0.12, 1.0))); 

    checkPos = p;  
    pR(checkPos.xy, 0.785);
    checkPos.xy = pModPolar(checkPos.xy, 4.0);

    missileDist=min(missileDist, sdJetHexPrism( checkPos-vec3(0., 0., .60), vec2(0.50, 0.01)));
    missileDist=min(missileDist, sdJetHexPrism( checkPos+vec3(0., 0., 1.03), vec2(0.50, 0.01)));
    missileDist = max(missileDist, -sdJetBox(p+vec3(0., 0., 3.15), vec3(3.0, 3.0, 2.0)));
    missileDist = max(missileDist, -fCylinder(p+vec3(0., 0., 2.15), 0.09, 1.2));
  }
  return missileDist;
}

float MapFrontWing(vec3 p, float mirrored)
{
  missileDist=10000.0;

  checkPos = p;
  pR(checkPos.xy, -0.02);
  float wing =sdJetBox( checkPos- vec3(4.50, 0.25, -4.6), vec3(3.75, 0.04, 2.6)); 

  if (wing<5.) //Bounding Box test
  {
    // cutouts
    checkPos = p-vec3(3.0, 0.3, -.30);
    pR(checkPos.xz, -0.5);
    wing=fOpIntersectionRound(wing, -sdJetBox( checkPos, vec3(6.75, 1.4, 2.0)), 0.1);

    checkPos = p - vec3(8.0, 0.3, -8.80);
    pR(checkPos.xz, -0.05);
    wing=fOpIntersectionRound(wing, -sdJetBox( checkPos, vec3(10.75, 1.4, 2.0)), 0.1);

    checkPos = p- vec3(9.5, 0.3, -8.50);
    wing=fOpIntersectionRound(wing, -sdJetBox( checkPos, vec3(2.0, 1.4, 6.75)), 0.6);

    // join wing and engine
    wing=min(wing, sdJetCapsule(p- vec3(2.20, 0.3, -4.2), vec3(0, 0, -1.20), vec3(0, 0, 0.8), 0.04));
    wing=min(wing, sdJetCapsule(p- vec3(3., 0.23, -4.2), vec3(0, 0, -1.20), vec3(0, 0, 0.5), 0.04));    

    checkPos = p;
    pR(checkPos.xz, -0.03);
    wing=min(wing, sdJetConeSection(checkPos- vec3(0.70, -0.1, -4.52), 5.0, 0.25, 0.9));   

    checkPos = p;
    pR(checkPos.yz, 0.75);
    wing=fOpIntersectionRound(wing, -sdJetBox( checkPos- vec3(3.0, -.5, 1.50), vec3(3.75, 3.4, 2.0)), 0.12); 
    pR(checkPos.yz, -1.95);
    wing=fOpIntersectionRound(wing, -sdJetBox( checkPos- vec3(2.0, .70, 2.20), vec3(3.75, 3.4, 2.0)), 0.12); 

    checkPos = p- vec3(0.47, 0.0, -4.3);
    pR(checkPos.yz, 1.57);
    wing=min(wing, sdJetTorus(checkPos-vec3(0.0, -3., .0), vec2(.3, 0.05)));   

    // flaps
    wing =max(wing, -sdJetBox( p- vec3(3.565, 0.1, -6.4), vec3(1.50, 1.4, .5)));
    wing =max(wing, -max(sdJetBox( p- vec3(5.065, 0.1, -8.4), vec3(0.90, 1.4, 2.5)), -sdJetBox( p- vec3(5.065, 0., -8.4), vec3(0.89, 1.4, 2.49))));

    checkPos = p- vec3(3.565, 0.18, -6.20+0.30);
    pR(checkPos.yz, -0.15+(0.8*pitch));
    wing =min(wing, sdJetBox( checkPos+vec3(0.0, 0.0, 0.30), vec3(1.46, 0.007, 0.3)));

    // missile holder
    float holder = sdJetBox( p- vec3(3.8, -0.26, -4.70), vec3(0.04, 0.4, 0.8));

    checkPos = p;
    pR(checkPos.yz, 0.85);
    holder=max(holder, -sdJetBox( checkPos- vec3(2.8, -1.8, -3.0), vec3(1.75, 1.4, 1.0))); 
    holder=max(holder, -sdJetBox( checkPos- vec3(2.8, -5.8, -3.0), vec3(1.75, 1.4, 1.0))); 
    holder =fOpUnionRound(holder, sdJetBox( p- vec3(3.8, -0.23, -4.70), vec3(1.0, 0.03, 0.5)), 0.1); 

    // bomb
    bombDist = fCylinder( p- vec3(3.8, -0.8, -4.50), 0.35, 1.);   
    bombDist =min(bombDist, sdJetEllipsoid( p- vec3(3.8, -0.8, -3.50), vec3(0.35, 0.35, 1.0)));   
    bombDist =min(bombDist, sdJetEllipsoid( p- vec3(3.8, -0.8, -5.50), vec3(0.35, 0.35, 1.0)));   

    // missiles
    checkPos = p-vec3(2.9, -0.45, -4.50);

    // check if any missile has been fired. If so, do NOT mod missile position  
    float maxMissiles =0.; 
    if (mirrored>0.) maxMissiles =  mix(1.0, 0., step(1., missilesLaunched.x));
    else maxMissiles =  mix(1.0, 0., step(1., missilesLaunched.y)); 

    pModInterval1(checkPos.x, 1.8, .0, maxMissiles);
    holder = min(holder, MapMissile(checkPos));

    // ESM Pod
    holder = min(holder, MapEsmPod(p-vec3(7.2, 0.06, -5.68)));

    // wheelholder
    wing=min(wing, sdJetBox( p- vec3(0.6, -0.25, -3.8), vec3(0.8, 0.4, .50)));

    wing=min(bombDist, min(wing, holder));
  }

  return wing;
}

float MapRearWing(vec3 p)
{
  float wing2 =sdJetBox( p- vec3(2.50, 0.1, -8.9), vec3(1.5, 0.017, 1.3)); 
  if (wing2<0.15) //Bounding Box test
  {
    // cutouts
    checkPos = p-vec3(3.0, 0.0, -5.9);
    pR(checkPos.xz, -0.5);
    wing2=fOpIntersectionRound(wing2, -sdJetBox( checkPos, vec3(6.75, 1.4, 2.0)), 0.2); 

    checkPos = p-vec3(0.0, 0.0, -4.9);
    pR(checkPos.xz, -0.5);
    wing2=fOpIntersectionRound(wing2, -sdJetBox( checkPos, vec3(3.3, 1.4, 1.70)), 0.2);

    checkPos = p-vec3(3.0, 0.0, -11.70);
    pR(checkPos.xz, -0.05);
    wing2=fOpIntersectionRound(wing2, -sdJetBox( checkPos, vec3(6.75, 1.4, 2.0)), 0.1); 

    checkPos = p-vec3(4.30, 0.0, -11.80);
    pR(checkPos.xz, 1.15);
    wing2=fOpIntersectionRound(wing2, -sdJetBox( checkPos, vec3(6.75, 1.4, 2.0)), 0.1);
  }
  return wing2;
} 

float MapTailFlap(vec3 p, float mirrored)
{
  p.z+=0.3;
  pR(p.xz, rudderAngle*(-1.*mirrored)); 
  p.z-=0.3;

  float tailFlap =sdJetBox(p- vec3(0., -0.04, -.42), vec3(0.025, .45, .30));

  // tailFlap front cutout
  checkPos = p- vec3(0., 0., 1.15);
  pR(checkPos.yz, 1.32);
  tailFlap=max(tailFlap, -sdJetBox( checkPos, vec3(.75, 1.41, 1.6)));

  // tailFlap rear cutout
  checkPos = p- vec3(0., 0, -2.75);  
  pR(checkPos.yz, -0.15);
  tailFlap=fOpIntersectionRound(tailFlap, -sdJetBox( checkPos, vec3(.75, 1.4, 2.0)), 0.05);

  checkPos = p- vec3(0., 0., -.65);
  tailFlap = min(tailFlap, sdJetEllipsoid( checkPos-vec3(0.00, 0.25, 0), vec3(0.06, 0.05, 0.15)));
  tailFlap = min(tailFlap, sdJetEllipsoid( checkPos-vec3(0.00, 0.10, 0), vec3(0.06, 0.05, 0.15)));

  return tailFlap;
}

float MapTopWing(vec3 p, float mirrored)
{    
  checkPos = p- vec3(1.15, 1.04, -8.5);
  pR(checkPos.xy, -0.15);  
  float topWing = sdJetBox( checkPos, vec3(0.014, 0.8, 1.2));
  if (topWing<.15) //Bounding Box test
  {
    float flapDist = MapTailFlap(checkPos, mirrored);

    checkPos = p- vec3(1.15, 1.04, -8.5);
    pR(checkPos.xy, -0.15);  
    // top border    
    topWing = min(topWing, sdJetBox( checkPos-vec3(0, 0.55, 0), vec3(0.04, 0.1, 1.25)));

    float flapCutout = sdJetBox(checkPos- vec3(0., -0.04, -1.19), vec3(0.02, .45, 1.0));
    // tailFlap front cutout
    checkPos = p- vec3(1.15, 2., -7.65);
    pR(checkPos.yz, 1.32);
    flapCutout=max(flapCutout, -sdJetBox( checkPos, vec3(.75, 1.41, 1.6)));

    // make hole for tail flap
    topWing=max(topWing, -flapCutout);

    // front cutouts
    checkPos = p- vec3(1.15, 2., -7.);
    pR(checkPos.yz, 1.02);
    topWing=fOpIntersectionRound(topWing, -sdJetBox( checkPos, vec3(.75, 1.41, 1.6)), 0.05);

    // rear cutout
    checkPos = p- vec3(1.15, 1., -11.25);  
    pR(checkPos.yz, -0.15);
    topWing=fOpIntersectionRound(topWing, -sdJetBox( checkPos, vec3(.75, 1.4, 2.0)), 0.05);

    // top roll 
    topWing=min(topWing, sdJetCapsule(p- vec3(1.26, 1.8, -8.84), vec3(0, 0, -.50), vec3(0, 0, 0.3), 0.06)); 

    topWing = min(topWing, flapDist);
  }
  return topWing;
}

float MapPlane( vec3 p)
{
  float  d=100000.0;
  vec3 pOriginal = p;
  // rotate position 
  p=TranslatePos(p, pitch, roll);
  float mirrored=0.;

  // mirror position at x=0.0. Both sides of the plane are equal.
  mirrored = pMirror(p.x, 0.0);

  float body= min(d, sdJetEllipsoid(p-vec3(0., 0.1, -4.40), vec3(0.50, 0.30, 2.)));
  body=fOpUnionRound(body, sdJetEllipsoid(p-vec3(0., 0., .50), vec3(0.50, 0.40, 3.25)), 1.);
  body=min(body, sdJetConeSection(p- vec3(0., 0., 3.8), 0.1, 0.15, 0.06));   

  body=min(body, sdJetConeSection(p- vec3(0., 0., 3.8), 0.7, 0.07, 0.01));   

  // window
  winDist =sdJetEllipsoid(p-vec3(0., 0.3, -0.10), vec3(0.45, 0.4, 1.45));
  winDist =fOpUnionRound(winDist, sdJetEllipsoid(p-vec3(0., 0.3, 0.60), vec3(0.3, 0.6, .75)), 0.4);
  winDist = max(winDist, -body);
  body = min(body, winDist) * 0.8;
  body=min(body, fOpPipe(winDist, sdJetBox(p-vec3(0., 0., 1.0), vec3(3.0, 1., .01)), 0.03) * 0.7);
  body=min(body, fOpPipe(winDist, sdJetBox(p-vec3(0., 0., .0), vec3(3.0, 1., .01)), 0.03) * 0.7);

  // front (nose)
  body=max(body, -max(fCylinder(p-vec3(0, 0, 2.5), .46, 0.04), -fCylinder(p-vec3(0, 0, 2.5), .35, 0.1)));
  checkPos = p-vec3(0, 0, 2.5);
  pR(checkPos.yz, 1.57);
  body=fOpIntersectionRound(body, -sdJetTorus(checkPos+vec3(0, 0.80, 0), vec2(.6, 0.05)), 0.015);
  body=fOpIntersectionRound(body, -sdJetTorus(checkPos+vec3(0, 2.30, 0), vec2(.62, 0.06)), 0.015);

  // wings       
  frontWingDist = MapFrontWing(p, mirrored);
  d=min(d, frontWingDist);   
  rearWingDist = MapRearWing(p);
  d=min(d, rearWingDist);
  topWingDist = MapTopWing(p, mirrored);
  d=min(d, topWingDist);

  // bottom
  checkPos = p-vec3(0., -0.6, -5.0);
  pR(checkPos.yz, 0.07);  
  d=fOpUnionRound(d, sdJetBox(checkPos, vec3(0.5, 0.2, 3.1)), 0.40);

  float holder = sdJetBox( p- vec3(0., -1.1, -4.30), vec3(0.08, 0.4, 0.8));  
  checkPos = p;
  pR(checkPos.yz, 0.85);
  holder=max(holder, -sdJetBox( checkPos- vec3(0., -5.64, -2.8), vec3(1.75, 1.4, 1.0))); 
  d=fOpUnionRound(d, holder, 0.25);

  // large bomb
  bombDist2 = fCylinder( p- vec3(0., -1.6, -4.0), 0.45, 1.);   
  bombDist2 =min(bombDist2, sdJetEllipsoid( p- vec3(0., -1.6, -3.20), vec3(0.45, 0.45, 2.)));   
  bombDist2 =min(bombDist2, sdJetEllipsoid( p- vec3(0., -1.6, -4.80), vec3(0.45, 0.45, 2.)));   

  d=min(d, bombDist2);

  d=min(d, sdJetEllipsoid(p- vec3(1.05, 0.13, -8.4), vec3(0.11, 0.18, 1.0)));    

  checkPos = p- vec3(0, 0.2, -5.0);
  d=fOpUnionRound(d, fOpIntersectionRound(sdJetBox( checkPos, vec3(1.2, 0.14, 3.7)), -sdJetBox( checkPos, vec3(1., 1.14, 4.7)), 0.2), 0.25);

  d=fOpUnionRound(d, sdJetEllipsoid( p- vec3(0, 0., -4.), vec3(1.21, 0.5, 2.50)), 0.75);

  // engine cutout
  blackDist = max(d, fCylinder(p- vec3(.8, -0.15, 0.), 0.5, 2.4)); 
  d=max(d, -fCylinder(p- vec3(.8, -0.15, 0.), 0.45, 2.4)); 

  // engine
  d =max(d, -sdJetBox(p-vec3(0., 0, -9.5), vec3(1.5, 0.4, 0.7)));

  engineDist=fCylinder(p- vec3(0.40, -0.1, -8.7), .42, 0.2);
  checkPos = p- vec3(0.4, -0.1, -8.3);
  pR(checkPos.yz, 1.57);
  engineDist=min(engineDist, sdJetTorus(checkPos, vec2(.25, 0.25)));
  engineDist=min(engineDist, sdJetConeSection(p- vec3(0.40, -0.1, -9.2), 0.3, .22, .36));

  checkPos = p-vec3(0., 0., -9.24);  
  checkPos.xy-=vec2(0.4, -0.1);
  checkPos.xy = pModPolar(checkPos.xy, 22.0);

  float engineCone = fOpPipe(engineDist, sdJetBox( checkPos, vec3(.6, 0.001, 0.26)), 0.015);
  engineDist=min(engineDist, engineCone);

  d=min(d, engineDist);
  
  d=min(d, winDist);
  d=min(d, body);

  d=min(d, sdJetBox( p- vec3(1.1, 0., -6.90), vec3(.33, .12, .17))); 
  checkPos = p-vec3(0.65, 0.55, -1.4);
  pR(checkPos.yz, -0.35);
  d=min(d, sdJetBox(checkPos, vec3(0.2, 0.1, 0.45)));

  return d;
}

float sdf(vec3 p) {
	p += vec3(0.,0.,0.8);
	p *= RotMat(vec3(0., 1., 0.), pi);
	const float scale = 0.12;
	p *= (1.0 / scale);
	return MapPlane(p) * 0.9 * scale;
}

#endif
