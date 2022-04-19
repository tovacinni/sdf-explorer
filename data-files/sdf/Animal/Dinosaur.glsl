/*
Copyright 2015 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4dtGWM
Archive Link: https://web.archive.org/web/20191107163057/https://www.shadertoy.com/view/4dtGWM
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

vec2 hash2(float n) {
  return fract(sin(vec2(n, n + 1.0)) * vec2(13.5453123, 31.1459123));
}

vec2 sdSegment(in vec3 p, vec3 a, vec3 b) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return vec2(length(pa - ba * h), h);
}

float sdSphere(in vec3 p, in vec3 c, in float r) { return length(p - c) - r; }

float sdEllipsoid(in vec3 p, in vec3 c, in vec3 r) {
  return (length((p - c) / r) - 1.0) * min(min(r.x, r.y), r.z);
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det(vec2 a, vec2 b) { return a.x * b.y - b.x * a.y; }
vec3 getClosest(vec2 b0, vec2 b1, vec2 b2) {

  float a = det(b0, b2);
  float b = 2.0 * det(b1, b0);
  float d = 2.0 * det(b2, b1);
  float f = b * d - a * a;
  vec2 d21 = b2 - b1;
  vec2 d10 = b1 - b0;
  vec2 d20 = b2 - b0;
  vec2 gf = 2.0 * (b * d21 + d * d10 + a * d20);
  gf = vec2(gf.y, -gf.x);
  vec2 pp = -f * gf / dot(gf, gf);
  vec2 d0p = b0 - pp;
  float ap = det(d0p, d20);
  float bp = 2.0 * det(d10, d0p);
  float t = clamp((ap + bp) / (2.0 * a + b + d), 0.0, 1.0);
  return vec3(mix(mix(b0, b1, t), mix(b1, b2, t), t), t);
}

vec2 sdBezier(vec3 a, vec3 b, vec3 c, vec3 p) {
  vec3 w = normalize(cross(c - b, a - b));
  vec3 u = normalize(c - b);
  vec3 v = normalize(cross(w, u));

  vec2 a2 = vec2(dot(a - b, u), dot(a - b, v));
  vec2 b2 = vec2(0.0);
  vec2 c2 = vec2(dot(c - b, u), dot(c - b, v));
  vec3 p3 = vec3(dot(p - b, u), dot(p - b, v), dot(p - b, w));

  vec3 cp = getClosest(a2 - p3.xy, b2 - p3.xy, c2 - p3.xy);

  return vec2(sqrt(dot(cp.xy, cp.xy) + p3.z * p3.z), cp.z);
}

vec2 sdLine(vec3 p, vec3 a, vec3 b) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return vec2(length(pa - ba * h), h);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 smin(vec2 a, vec2 b, float k) {
  float h = clamp(0.5 + 0.5 * (b.x - a.x) / k, 0.0, 1.0);
  return vec2(mix(b.x, a.x, h) - k * h * (1.0 - h), mix(b.y, a.y, h));
}

float smax(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(a, b, h) + k * h * (1.0 - h);
}

mat3 base(in vec3 ww) {
  vec3 vv = vec3(0.0, 0.0, 1.0);
  vec3 uu = normalize(cross(vv, ww));
  return mat3(uu.x, ww.x, vv.x, uu.y, ww.y, vv.y, uu.z, ww.z, vv.z);
}

//---------------------------------------------------------------------------

vec2 leg(in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h) {
  float l = sign(pa.z);

  vec2 b = sdLine(p, pa, pb);

  float tr = 0.15; // - 0.2*b.y;
  float d3 = b.x - tr;

  b = sdLine(p, pb, pc);
  tr = 0.15; // - 0.2*b.y;
  d3 = smin(d3, b.x - tr, 0.1);

  // knee
  float d4 = sdEllipsoid(p, pb + vec3(-0.02, 0.05, 0.0), vec3(0.14));
  // d4 -= 0.01*abs(sin(50.0*p.y));
  d4 -= 0.015 * abs(sin(40.0 * p.y));
  d3 = smin(d3, d4, 0.05);

  // paw
  vec3 ww = normalize(mix(normalize(pc - pb), vec3(0.0, 1.0, 0.0), h));
  mat3 pr = base(ww);
  vec3 fc = pr * ((p - pc)) - vec3(0.2, 0.0, 0.0) * (-1.0 + 2.0 * h);
  d4 = sdEllipsoid(fc, vec3(0.0), vec3(0.4, 0.25, 0.4));

  // nails
  float d6 = sdEllipsoid(fc, vec3(0.32, -0.06, 0.0) * (-1.0 + 2.0 * h),
                         0.95 * vec3(0.1, 0.2, 0.15));
  d6 = min(d6, sdEllipsoid(vec3(fc.xy, abs(fc.z)),
                           vec3(0.21 * (-1.0 + 2.0 * h),
                                -0.08 * (-1.0 + 2.0 * h), 0.26),
                           0.95 * vec3(0.1, 0.2, 0.15)));
  // space for nails
  d4 = smax(d4, -d6, 0.03);

  // shape paw
  float d5 = sdEllipsoid(fc, vec3(0.0, 1.85 * (-1.0 + 2.0 * h), 0.0),
                         vec3(2.0, 2.0, 2.0));
  d4 = smax(d4, d5, 0.03);
  d6 = smax(d6, d5, 0.03);
  d5 = sdEllipsoid(fc, vec3(0.0, -0.75 * (-1.0 + 2.0 * h), 0.0),
                   vec3(1.0, 1.0, 1.0));
  d4 = smax(d4, d5, 0.03);
  d6 = smax(d6, d5, 0.03);

  d3 = smin(d3, d4, 0.1);

  // muslo
  d4 = sdEllipsoid(p, pa + vec3(0.0, 0.2, -0.1 * l), vec3(0.35) * m);
  d3 = smin(d3, d4, 0.1);

  return vec2(d3, d6);
}

float mapArlo(vec3 p) {

  // body
  vec3 q = p;
  float co = cos(0.2);
  float si = sin(0.2);
  q.xy = mat2(co, si, -si, co) * q.xy;
  float d1 = sdEllipsoid(q, vec3(0.0, 0.0, 0.0), vec3(1.3, 0.75, 0.8));
  float d2 = sdEllipsoid(q, vec3(0.05, 0.45, 0.0), vec3(0.8, 0.6, 0.5));
  float d = smin(d1, d2, 0.4);

  // neck wrinkles
  float r = length(p - vec3(-1.2, 0.2, 0.0));
  d -= 0.05 * abs(sin(35.0 * r)) * exp(-7.0 * abs(r)) *
       clamp(1.0 - (p.y - 0.3) * 10.0, 0.0, 1.0);

  // tail
  {
    vec2 b = sdBezier(vec3(1.0, -0.4, 0.0), vec3(2.0, -0.96, -0.5),
                      vec3(3.0, -0.5, 1.5), p);
    float tr = 0.3 - 0.25 * b.y;
    float d3 = b.x - tr;
    d = smin(d, d3, 0.2);
  }

  // neck
  {
    vec2 b = sdBezier(vec3(-0.9, 0.3, 0.0), vec3(-2.2, 0.5, 0.0),
                      vec3(-2.6, 1.7, 0.0), p);
    float tr = 0.35 - 0.23 * b.y;
    float d3 = b.x - tr;
    d = smin(d, d3, 0.15);
    // d = min(d,d3);
  }

  float dn;
  // front-left leg
  {
    vec2 d3 = leg(p, vec3(-0.8, -0.1, 0.5), vec3(-1.5, -0.5, 0.65),
                  vec3(-1.9, -1.1, 0.65), 1.0, 0.0);
    d = smin(d, d3.x, 0.2);
    dn = d3.y;
  }
  // back-left leg
  {
    vec2 d3 = leg(p, vec3(0.5, -0.4, 0.6), vec3(0.3, -1.05, 0.6),
                  vec3(0.8, -1.6, 0.6), 0.5, 1.0);
    d = smin(d, d3.x, 0.2);
    dn = min(dn, d3.y);
  }
  // front-right leg
  {
    vec2 d3 = leg(p, vec3(-0.8, -0.2, -0.5), vec3(-1.0, -0.9, -0.65),
                  vec3(-0.7, -1.6, -0.65), 1.0, 1.0);
    d = smin(d, d3.x, 0.2);
    dn = min(dn, d3.y);
  }
  // back-right leg
  {
    vec2 d3 = leg(p, vec3(0.5, -0.4, -0.6), vec3(0.8, -0.9, -0.6),
                  vec3(1.6, -1.1, -0.7), 0.5, 0.0);
    d = smin(d, d3.x, 0.2);
    dn = min(dn, d3.y);
  }

  // head
  vec3 s = vec3(p.xy, abs(p.z));
  {
    vec2 l = sdLine(p, vec3(-2.7, 2.36, 0.0), vec3(-2.6, 1.7, 0.0));
    float d3 = l.x - (0.22 - 0.1 * smoothstep(0.1, 1.0, l.y));

    // mouth
    // l = sdLine( p, vec3(-2.7,2.16,0.0), vec3(-3.35,2.12,0.0) );
    vec3 mp = p - vec3(-2.7, 2.16, 0.0);
    l = sdLine(mp * vec3(1.0, 1.0, 1.0 - 0.2 * abs(mp.x) / 0.65), vec3(0.0),
               vec3(-3.35, 2.12, 0.0) - vec3(-2.7, 2.16, 0.0));

    float d4 = l.x - (0.12 + 0.04 * smoothstep(0.0, 1.0, l.y));
    float d5 = sdEllipsoid(s, vec3(-3.4, 2.5, 0.0), vec3(0.8, 0.5, 2.0));
    d4 = smax(d4, d5, 0.03);

    d3 = smin(d3, d4, 0.1);

    // mouth bottom
    {
      vec2 b = sdBezier(vec3(-2.6, 1.75, 0.0), vec3(-2.7, 2.2, 0.0),
                        vec3(-3.25, 2.12, 0.0), p);
      float tr = 0.11 + 0.02 * b.y;
      d4 = b.x - tr;
      d3 = smin(d3, d4, 0.001 + 0.06 * (1.0 - b.y * b.y));
    }

    // brows
    vec2 b = sdBezier(vec3(-2.84, 2.50, 0.04), vec3(-2.81, 2.52, 0.15),
                      vec3(-2.76, 2.4, 0.18), s + vec3(0.0, -0.02, 0.0));
    float tr = 0.035 - 0.025 * b.y;
    d4 = b.x - tr;
    d3 = smin(d3, d4, 0.025);

    // eye wholes
    d4 = sdEllipsoid(s, vec3(-2.79, 2.36, 0.04), vec3(0.12, 0.15, 0.15));
    d3 = smax(d3, -d4, 0.025);

    // nose holes
    d4 = sdEllipsoid(s, vec3(-3.4, 2.17, 0.09), vec3(0.1, 0.025, 0.025));
    d3 = smax(d3, -d4, 0.04);

    d = smin(d, d3, 0.01);
  }
  // vec2 res = vec2(d, 0.0);

  // eyes
  float d4 = sdSphere(s, vec3(-2.755, 2.36, 0.045), 0.16);

  d = min(d, min(dn, d4));

  return d;
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

float sdf(vec3 p) {
  p = p * RotMat(vec3(0.,1.,0.), -(3.14/2));
  const float scale = 0.25;
  p *= 1. / scale;
  return mapArlo(p) * scale;
}

