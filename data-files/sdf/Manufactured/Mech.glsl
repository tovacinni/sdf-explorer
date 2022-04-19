/*
Copyright 2020 @dean_the_coder
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wsGczG
*/

/******************************************************************************
 This work is a derivative of work by dean_the_coder used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef mech_glsl
#define mech_glsl

// ED-209
//
// I've always loved the (original) Robocop movie, but have never
// felt confident enough to try modelling ED-209.
// I hope you like it!
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

#define MIN_DIST      0.0015
#define MAX_DIST      64.0
#define MAX_STEPS     120.0
#define SHADOW_STEPS  30.0

float stretch, gunsUp, gunsForward, edWalk, edTwist, edDown, edShoot, doorOpen, glow;

//#define AA  // Enable this line if your GPU can take it!

struct MarchData {
    float d;
    vec3 mat;        // RGB
    float specPower; // 0: None, 30.0: Shiny
};

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

float remap(float f, float in1, float in2, float out1, float out2) {
    return mix(out1, out2, clamp((f - in1) / (in2 - in1), 0.0, 1.0));
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdChamferedCube(vec3 p, vec3 r, float c) {
    float cube = sdBox(p, r);
    p.xz *= rot(3.141 / 4.0);
    r.xz *= -c / 1.41 + 1.41;
    return max(cube, sdBox(p, r));
}

float sdTriPrism(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float sdCappedCone(vec3 p, vec3 a, vec3 b, float ra, float rb) {
  float rba  = rb-ra,
     baba = dot(b-a,b-a),
     papa = dot(p-a,p-a),
     paba = dot(p-a,b-a)/baba,
     x = sqrt( papa - paba*paba*baba ),
     cax = max(0.0,x-((paba<0.5)?ra:rb)),
     cay = abs(paba-0.5)-0.5,
     k = rba*rba + baba,
     f = clamp( (rba * (x - ra) + paba * baba) / k, 0.0, 1.0 ),
     cbx = x - ra - f * rba,
     cby = paba - f,
     s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(cax*cax + cay*cay*baba, cbx*cbx + cby*cby*baba) );
}

float sdCappedCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xy), p.z)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h) - r;
}

float sdOctogon(vec2 p, float r)
{
    const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623);
    p = abs(p);
    p -= 2.0 * min(dot(vec2( k.x, k.y), p), 0.0) * vec2( k.x, k.y);
    p -= 2.0 * min(dot(vec2(-k.x, k.y), p), 0.0) * vec2(-k.x, k.y);
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

vec3 getRayDir(vec3 ro, vec3 lookAt, vec2 uv) {
    vec3 forward = normalize(lookAt - ro),
         right = normalize(cross(vec3(0.0, 1.0, 0.0), forward)),
         up = cross(forward, right);
    return normalize(forward + right * uv.x + up * uv.y);
}

MarchData minResult(MarchData a, MarchData b) {
    if (a.d < b.d) return a;
    return b;
}

void setBodyMaterial(inout MarchData mat) {
    mat.mat = vec3(0.36, 0.45, 0.5);
    mat.specPower = 30.0;
}

float legWalkAngle(float f) { return sin(edWalk * 3.141 * 6.0 * f) * 0.2; }
float edZ() { return mix(5.0, -2.0, edWalk); }
float fireShock() { return abs(sin(edShoot * 3.1415 * 25.0)); }

float headSphere(vec3 p) {
    return (length(p / vec3(1.0, 0.8, 1.0)) - 1.0) * 0.8;
}

MarchData headVisor(vec3 p, float h, float bump) {
    bump *= sin(p.x * 150.0) * sin(p.y * 150.0) * 0.002;

    MarchData result;

    result.d = sdBox(p, vec3(1.0, h, 2.0));
    result.d = max(mix(result.d, headSphere(p), 0.57), -p.y) - bump;
    
    result.mat = vec3(0.05);
    result.specPower = 30.0;
    return result;
}

MarchData headLower(vec3 p) {
    vec3 op = p;

    // Start by mirroring the visor.
    MarchData r = headVisor(p * vec3(0.95, -1.4, 0.95), 1.0, 0.0);
    
    // Add the side panels.
    float roof = max(max(headVisor((p + vec3(0.0, 0.01, 0.0)) * vec3(0.95), 1.0, 0.0).d, p.y - 0.35), p.y * 0.625 - p.z - 0.66);
    r.d = min(r.d, roof);

    // 'Wings'.
    p.xy *= rot(0.075 * (gunsUp - 1.0) * sign(p.x));
    p.x = abs(p.x) - 1.33;
    p.y -= 0.1 - p.x * 0.1;
    r.d = min(r.d, sdBox(p, vec3(0.4, 0.06 * (1.0 - p.x), 0.3 - (p.x * 0.2))));
    p = op;
    
    // Cut out a mouth grill.
    p.y = abs(abs(p.y + 0.147) - 0.1 * 0.556) - 0.05 * 0.556;
    r.d = max(r.d, -sdBox(p + vec3(0.0, 0.0, 1.5), vec3(mix(0.25, 0.55, -op.y), 0.015, 0.1)));
    
    // 'Cheeks'.
    p = op;
    p.y = abs(p.y + 0.16) - 0.06;
    p.z -= -1.1;
    float cheeks = max(sdCappedCylinder(p.xzy, 1.0, 0.03), -sdCappedCylinder(p.xzy, 0.55, 1.0));
    cheeks = max(cheeks, p.z + 0.2);
    r.d = max(r.d, -cheeks);
    
    setBodyMaterial(r);
    return r;
}

MarchData gunPod(vec3 p) {
    MarchData r;
    setBodyMaterial(r);
    
    p.yz += vec2(0.1, 0.45);

    // Carousel.
    const float rr = 0.35, chamfer = 0.1;
    vec3 pp = p;
    pp.z = abs(pp.z) - 0.5;
    r.d = sdCappedCone(pp, vec3(0.0), vec3(0.0, 0.0, -chamfer), rr - chamfer, rr);
    r.d = min(r.d, sdCappedCylinder(p, rr, 0.4));
    
    // Triangle nobble.
    pp = vec3(p.x, 0.28 - p.y, p.z);
    r.d = min(r.d, sdTriPrism(pp, vec2(0.1, 0.5)));

    // Square outriggers.
    pp = p;
    pp.x = abs(p.x);
    pp.xy *= rot(3.141 / 4.0);
    float bump = sign(sin(pp.z * 33.3)) * 0.003,
          d = sdBox(pp, vec3(0.1 - bump, 0.38 - bump, 0.34)) - 0.02;
    
    // Barrels.
    pp = p - vec3(0.0, 0.0, -0.6);
    pp.x = abs(pp.x) - 0.1;
    d = min(d, sdCappedCylinder(pp, 0.06, 0.15));
    d = min(d, sdCappedCylinder(pp + vec3(0.0, 0.12, -0.05), 0.06, 0.05));
    d = min(d, sdBox(p + vec3(0.0, 0.0, 0.54), vec3(0.1, 0.06, 0.04)));
    if (d < r.d) {
        d = max(d, -sdCappedCylinder(pp + vec3(0.0, 0.0, 0.1), 0.03, 0.2));
        r.d = d;
        r.mat = vec3(0.02);
    }
    
    // Muzzle flash.
    float fs = fireShock();
    if (fs > 0.5) {
        d = sdCappedCylinder(pp, 0.01 + pp.z * 0.05, fract(fs * 3322.423) * 0.5 + 0.9);
        if (d < r.d) {
            r.d = d;
            r.mat = vec3(1.0);
            glow += 0.1 / (0.01 + d * d * 400.0);
        }
    }
   
    return r;
}

MarchData arms(vec3 p) {
    MarchData r;
    setBodyMaterial(r);

    // Position origin.
    p.x = abs(p.x);
    p.yz += vec2(0.24, -0.0);
    p.xy *= rot(0.15 * (gunsUp - 1.0));
    
    // Shoulder and forearm.
    const vec3 elbow = vec3(1.5, 0.0, 0.0), wrist = elbow - vec3(0.0, 0.0, 0.3);
    r.d = min(sdCapsule(p, vec3(0.0), elbow, 0.2), sdCapsule(p, elbow, wrist, 0.2));
    
    // Gunz.
    p -= wrist;
    p.z -= gunsForward * 0.15;
    return minResult(r, gunPod(p));
}

float toe(vec3 p) {
    p.yz += vec2(0.1, 0.32);
    return max(sdBox(p, vec3(0.3 + 0.2 * (p.z - 0.18) - (p.y * 0.456) * 0.5, 0.3 + 0.2 * cos((p.z - 0.18) * 3.69), 0.35)), 0.1 - p.y);
}

float foot(vec3 p) {
    p.z += 0.8;
    p.yz *= rot(0.86);
    
    float d = toe(p);
    p.xz *= rot(1.57);
    p.x -= 0.43;
    p.z = 0.25 - abs(p.z);
    
    return min(d, toe(p));
}

MarchData waist(vec3 p) {
    MarchData r;
    setBodyMaterial(r);

    p.y += 0.65;
    p.yz *= rot(-0.2);
    float legAngle = legWalkAngle(1.0);
    p.xy *= rot(legAngle * 0.3);
    
    vec3 pp = p;
    pp.y += 0.3;
    r.d = max(sdCappedCylinder(pp.zyx, 0.5, 0.5), p.y + 0.15);

    // Thorax.
    float bump = 0.5 - abs(sin(p.y * 40.0)) * 0.03;
    float d = sdBox(p, vec3(bump, 0.15, bump));
    
    // Leg joins.
    bump = 0.3 - abs(sin(p.x * 40.0)) * 0.03;
    pp.y += 0.18;
    d = min(d, sdCappedCylinder(pp.zyx, bump, 0.75));
    
    // Hips.
    pp.x = abs(pp.x);
    pp.yz *= rot(0.2 - 3.141 / 4.0 + legAngle * sign(p.x));
    pp.x -= 0.98;
    r.d = min(r.d, max(sdCappedCylinder(pp.zyx, 0.4, 0.24), -pp.y));
    r.d = min(r.d, sdBox(pp, vec3(0.24, 0.2, 0.14 + 0.2 * pp.y)));
    
    // Thigh pistons.
    vec3 cp = pp;
    p = pp;
    pp.xz = abs(pp.xz) - vec2(0.12, 0.25);
    float pistons = min(sdCappedCylinder(pp.xzy, 0.1, 0.325), sdCappedCylinder(pp.xzy, 0.05, 0.5));
    r.d = min(r.d, max(pistons, pp.y));
    
    // 'Knees'.
    p.y += 0.68;
    r.d = min(r.d, sdBox(p, vec3(sign(abs(p.y) - 0.04) * 0.005 + 0.26, 0.2, 0.34)));
    
    if (d < r.d) {
        // Black segments.
        r.d = d;
        r.mat = vec3(0.02);
    }
    
    return r;
}

MarchData legs(vec3 p) {
    MarchData r;
    setBodyMaterial(r);

    float legAngle = legWalkAngle(1.0);
    p.z += 0.27;
    p.yz *= rot(legAngle * sign(p.x));
    p.z -= 0.27;
    
    p.y += 0.65;
    p.yz *= rot(-0.2);
    p.xy *= rot(legAngle * 0.3);
    
    vec3 pp = p;
    pp.x = abs(pp.x);
    pp.y += 0.48;
    pp.yz *= rot(0.2 - 3.141 / 4.0);
    pp.x -= 0.98;
    
    vec3 cp = pp;
    p = pp;
    pp.xz = abs(pp.xz) - vec2(0.12, 0.25);
    p.y += 0.68;
    
    // Thighs.
    p.xy = abs(p.xy) - 0.12;
    float silver = sdBox(p, vec3(0.07, 0.05, 1.2));
    
    // Leg end cap.
    cp -= vec3(0.0, -0.7, 0.0);
    r.d = sdBox(cp - vec3(0.0, 0.0, 1.15), vec3(0.17, 0.17, 0.07)) - 0.04;
    
    // Shin.
    cp.z += 1.0;
    r.d = min(r.d, sdChamferedCube(cp.xzy, vec2(0.28 - sign(abs(cp.z) - 0.3) * 0.01, 0.5).xyx, 0.18));
    
    // Feet.
    r.d = min(r.d, foot(cp));
    
    if (silver < r.d) {
        r.d = silver;
        r.mat = vec3(0.8);
    }
    
    return r;
}

MarchData ed209(vec3 p) {
    p.yz += vec2(legWalkAngle(2.0) * 0.2 + 0.1, -edZ());
    
    MarchData r = legs(p);
    
    float f = min(stretch * 2.0, 1.0),
          slide = f < 0.5 ? smoothstep(0.0, 0.5, f) : (1.0 - smoothstep(0.5, 1.0, f) * 0.2);
    p.yz -= slide * 0.5;
    gunsUp = smoothstep(0.0, 1.0, clamp((stretch - 0.66) * 6.0, 0.0, 1.0)); // 0.66-0.83
    gunsForward = smoothstep(0.0, 1.0, clamp((stretch - 0.83) * 6.0, 0.0, 1.0)) // 0.83-1.0
                  + fireShock() * 0.5;
    r = minResult(r, waist(p));

    p.yz *= rot(0.1 * (-edDown + legWalkAngle(2.0) + smoothstep(0.0, 1.0, clamp((stretch - 0.5) * 6.0, 0.0, 1.0)) - 1.0)); // 0.5-0.66
    p.xz *= rot(edTwist * 0.2);
    r = minResult(r, headLower(p));
    r = minResult(r, headVisor(p, 0.8, 1.0));

    return minResult(r, arms(p));
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

float sdf(vec3 p)
{
    p = p * RotMat(vec3(0.,1.,0.), 3.14);
    p += vec3(-0.11,-0.25,2.0);
    const float scale = 0.4;
    p *= 1. / scale;
    stretch = 2.0 * (sin(g3d_SceneTime*2.0) + 1.0);
    return ed209(p).d * scale * 0.8;
}

#endif 

