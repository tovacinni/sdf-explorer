/*
Copyright 2016 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4dKGWm
Archive Link: https://web.archive.org/web/20191112085742/https://www.shadertoy.com/view/4dKGWm
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

float hash1(float n) { return fract(sin(n) * 43758.5453123); }

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

vec2 sdSegment(in vec3 p, vec3 a, vec3 b) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return vec2(length(pa - ba * h), h);
}

float sdSphere(in vec3 p, in vec3 c, in float r) { return length(p - c) - r; }

float sdEllipsoid(in vec3 p, in vec3 c, in vec3 r) {
#if 1
  return (length((p - c) / r) - 1.0) * min(min(r.x, r.y), r.z);
#else
  p -= c;
  float k0 = length(p / r);
  float k1 = length(p / (r * r));
  return k0 * (k0 - 1.0) / k1;
#endif
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

vec2 sdBezier(vec3 a, vec3 b, vec3 c, vec3 p, out vec2 pos) {
  vec3 w = normalize(cross(c - b, a - b));
  vec3 u = normalize(c - b);
  vec3 v = normalize(cross(w, u));

  vec2 a2 = vec2(dot(a - b, u), dot(a - b, v));
  vec2 b2 = vec2(0.0);
  vec2 c2 = vec2(dot(c - b, u), dot(c - b, v));
  vec3 p3 = vec3(dot(p - b, u), dot(p - b, v), dot(p - b, w));

  vec3 cp = getClosest(a2 - p3.xy, b2 - p3.xy, c2 - p3.xy);

  pos = cp.xy;

  return vec2(sqrt(dot(cp.xy, cp.xy) + p3.z * p3.z), cp.z);
}

//---------------------------------------------------------------------------

mat3 base(in vec3 ww) {
  vec3 vv = vec3(0.0, 0.0, 1.0);
  vec3 uu = normalize(cross(vv, ww));
  return mat3(uu.x, ww.x, vv.x, uu.y, ww.y, vv.y, uu.z, ww.z, vv.z);
}

//---------------------------------------------------------------------------

float leg(in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h) {
  float l = sign(pa.z);

  vec2 b = sdSegment(p, pa, pb);

  float tr = 0.35 - 0.16 * smoothstep(0.0, 1.0, b.y);
  float d3 = b.x - tr;

  b = sdSegment(p, pb, pc);
  tr = 0.18;
  d3 = smin(d3, b.x - tr, 0.1);

  // paw
  vec3 ww = normalize(mix(normalize(pc - pb), vec3(0.0, 1.0, 0.0), h));
  mat3 pr = base(ww);
  vec3 fc = pr * ((p - pc)) - vec3(0.02, 0.0, 0.0) * (-1.0 + 2.0 * h);
  float d4 = sdEllipsoid(fc, vec3(0.0), vec3(0.2, 0.15, 0.2));

  d3 = smin(d3, d4, 0.1);

  // nails
  float d6 = sdEllipsoid(fc, vec3(0.14, -0.06, 0.0) * (-1.0 + 2.0 * h),
                         vec3(0.1, 0.16, 0.1));
  d6 = min(d6, sdEllipsoid(vec3(fc.xy, abs(fc.z)),
                           vec3(0.13 * (-1.0 + 2.0 * h),
                                -0.08 * (-1.0 + 2.0 * h), 0.13),
                           vec3(0.09, 0.14, 0.1)));
  d3 = smin(d3, d6, 0.001);
  return d3;
}

float mapElephant(vec3 p, out vec3 matInfo) {
  matInfo = vec3(0.0);

  p.x -= -0.5;
  p.y -= 2.4;

  vec3 ph = p;
  float cc = 0.995;
  float ss = 0.0998745;
  ph.yz = mat2(cc, -ss, ss, cc) * ph.yz;
  ph.xy = mat2(cc, -ss, ss, cc) * ph.xy;

  // head
  float d1 = sdEllipsoid(ph, vec3(0.0, 0.05, 0.0), vec3(0.45, 0.5, 0.3));
  d1 = smin(d1, sdEllipsoid(ph, vec3(-0.3, 0.15, 0.0), vec3(0.2, 0.2, 0.2)),
            0.1);

  // nose
  vec2 kk;
  vec2 b1 = sdBezier(vec3(-0.15, -0.05, 0.0), vec3(-0.7, 0.0, 0.0),
                     vec3(-0.7, -0.8, 0.0), ph, kk);
  float tr1 = 0.30 - 0.17 * smoothstep(0.0, 1.0, b1.y);
  vec2 b2 = sdBezier(vec3(-0.7, -0.8, 0.0), vec3(-0.7, -1.5, 0.0),
                     vec3(-0.4, -1.6, 0.2), ph, kk);
  float tr2 = 0.30 - 0.17 - 0.05 * smoothstep(0.0, 1.0, b2.y);
  float bd1 = b1.x - tr1;
  float bd2 = b2.x - tr2;
  float nl = b1.y * 0.5;
  float bd = bd1;
  if (bd2 < bd1) {
    nl = 0.5 + 0.5 * b2.y;
    bd = bd2;
  }
  matInfo.x = clamp(nl * (1.0 - smoothstep(0.0, 0.2, bd)), 0.0, 1.0);
  float d2 = bd;
  float xx = nl * 120.0;
  float ff = sin(xx + sin(xx + sin(xx + sin(xx))));
  // ff *= smoothstep(0.0,0.01,kk.y);
  d2 += 0.003 * ff * (1.0 - nl) * (1.0 - nl) * smoothstep(0.0, 0.1, nl);

//   d2 -= (0.05 -
//          0.05 * (1.0 -
//                  pow(textureLod(iChannel0, vec2(1.0 * nl, p.z * 0.12), 0.0).x,
//                      1.0))) *
//         nl * (1.0 - nl) * 0.5;

  float d = smin(d1, d2, 0.2);

  // teeth
  vec3 q = vec3(p.xy, abs(p.z));
  vec3 qh = vec3(ph.xy, abs(ph.z));
  {
    vec2 s1 = sdSegment(qh, vec3(-0.4, -0.1, 0.1), vec3(-0.5, -0.4, 0.28));
    float d3 = s1.x - 0.18 * (1.0 - 0.3 * smoothstep(0.0, 1.0, s1.y));
    d = smin(d, d3, 0.1);
  }

  // eyes
  {
    vec2 s1 = sdSegment(qh, vec3(-0.2, 0.2, 0.11), vec3(-0.3, -0.0, 0.26));
    float d3 = s1.x - 0.19 * (1.0 - 0.3 * smoothstep(0.0, 1.0, s1.y));
    d = smin(d, d3, 0.03);

    float st = length(qh.xy - vec2(-0.31, -0.02));
    // d += 0.005*sin(250.0*st)*exp(-110.0*st*st );
    d += 0.0015 * sin(250.0 * st) * (1.0 - smoothstep(0.0, 0.2, st));

    mat3 rot = mat3(0.8, -0.6, 0.0, 0.6, 0.8, 0.0, 0.0, 0.0, 1.0);
    float d4 = sdEllipsoid(rot * (qh - vec3(-0.31, -0.02, 0.34)), vec3(0.0),
                           vec3(0.1, 0.08, 0.07) * 0.7);
    d = smax(d, -d4, 0.02);
  }

  // body
  {
    float co = cos(0.4);
    float si = sin(0.4);
    vec3 w = p;
    w.xy = mat2(co, si, -si, co) * w.xy;

    float d4 = sdEllipsoid(w, vec3(0.6, 0.3, 0.0), vec3(0.6, 0.6, 0.6));
    d = smin(d, d4, 0.1);

    d4 = sdEllipsoid(w, vec3(1.8, 0.3, 0.0), vec3(1.2, 0.9, 0.7));
    d = smin(d, d4, 0.2);

    d4 = sdEllipsoid(w, vec3(2.1, 0.55, 0.0), vec3(1.0, 0.9, 0.6));
    d = smin(d, d4, 0.1);

    d4 = sdEllipsoid(w, vec3(2.0, 0.8, 0.0), vec3(0.7, 0.6, 0.8));
    d = smin(d, d4, 0.1);
  }

  // back-left leg
  {
    float d3 = leg(q, vec3(2.6, -0.5, 0.3), vec3(2.65, -1.45, 0.3),
                   vec3(2.6, -2.1, 0.25), 1.0, 0.0);
    d = smin(d, d3, 0.1);
  }

  // tail
#if 1
    {
    vec2 b = sdBezier( vec3(2.8,0.2,0.0), vec3(3.4,-0.6,0.0), vec3(3.1,-1.6,0.0), p, kk );
    float tr = 0.10 - 0.07*b.y;
    float d2 = b.x - tr;
    d = smin( d, d2, 0.05 );
    }
#endif

// front-left leg
#if 0
    {
    float d3 = leg( q, vec3(0.8,-0.4,0.3), vec3(0.5,-1.55,0.3), vec3(0.5,-2.1,0.3), 1.0, 0.0 );
    d = smin(d,d3,0.15);
    }
#else
  {
    float d3 = leg(p, vec3(0.8, -0.4, 0.3), vec3(0.7, -1.55, 0.3),
                   vec3(0.8, -2.1, 0.3), 1.0, 0.0);
    d = smin(d, d3, 0.15);
    d3 = leg(p, vec3(0.8, -0.4, -0.3), vec3(0.4, -1.55, -0.3),
             vec3(0.4, -2.1, -0.3), 1.0, 0.0);
    d = smin(d, d3, 0.15);
  }
#endif

#if 1
  // ear
  float co = cos(0.5);
  float si = sin(0.5);
  vec3 w = qh;
  w.xz = mat2(co, si, -si, co) * w.xz;

  vec2 ep = w.zy - vec2(0.5, 0.4);
  float aa = atan(ep.x, ep.y);
  float al = length(ep);
  w.x += 0.003 * sin(24.0 * aa) * smoothstep(0.0, 0.5, dot(ep, ep));
//   w.x += 0.02 *
//          textureLod(iChannel1, vec2(al * 0.02, 0.5 + 0.05 * sin(aa)), 0.0).x *
//          smoothstep(0.0, 0.3, dot(ep, ep));

  float r =
      0.02 * sin(24.0 * atan(ep.x, ep.y)) * clamp(-w.y * 1000.0, 0.0, 1.0);
  r += 0.01 * sin(15.0 * w.z);
  // section
  float d4 = length(w.zy - vec2(0.5, -0.2 + 0.03)) - 0.8 + r;
  float d5 = length(w.zy - vec2(-0.1, 0.6 + 0.03)) - 1.5 + r;
  float d6 = length(w.zy - vec2(1.8, 0.1 + 0.03)) - 1.6 + r;
  d4 = smax(d4, d5, 0.1);
  d4 = smax(d4, d6, 0.1);

  float wi =
      0.02 + 0.1 * pow(clamp(1.0 - 0.7 * w.z + 0.3 * w.y, 0.0, 1.0), 2.0);
  w.x += 0.05 * cos(6.0 * w.y);

  // cut it!
  d4 = smax(d4, -w.x, 0.03);
  d4 = smax(d4, w.x - wi, 0.03);

  matInfo.y = clamp(length(ep), 0.0, 1.0) * (1.0 - smoothstep(-0.1, 0.05, d4));

  d = smin(d, d4, 0.3 * max(qh.y, 0.0)); // trick -> positional smooth

  // conection hear/head
  vec2 s1 = sdBezier(vec3(-0.15, 0.3, 0.0), vec3(0.1, 0.6, 0.2),
                     vec3(0.35, 0.6, 0.5), qh, kk);
  float d3 = s1.x - 0.08 * (1.0 - 0.95 * s1.y * s1.y);
  d = smin(d, d3, 0.05);

#endif

//   d -= 0.002 * textureLod(iChannel1, 0.5 * p.yz, 0.0).x;
//   d -= 0.002 * textureLod(iChannel1, 0.5 * p.yx, 0.0).x;
//   d += 0.003;
//   d -= 0.005 * textureLod(iChannel0, 0.5 * p.yx, 0.0).x *
//        (0.2 + 0.8 * smoothstep(0.8, 1.3, length(p - vec3(-0.5, 0.0, 0.0))));

  vec2 res = vec2(d, 0.0);
  //=====================
  // teeth
  vec2 b = sdBezier(vec3(-0.5, -0.4, 0.28), vec3(-0.5, -0.7, 0.32),
                    vec3(-1.0, -0.8, 0.45), qh, kk);
  float tr = 0.10 - 0.08 * b.y;
  d2 = b.x - tr;
  if (d2 < res.x) {
    res = vec2(d2, 1.0);
    matInfo.x = b.y;
  }
  //------------------
  // eyeball
  mat3 rot = mat3(0.8, -0.6, 0.0, 0.6, 0.8, 0.0, 0.0, 0.0, 1.0);
  d4 = sdEllipsoid(rot * (qh - vec3(-0.31, -0.02, 0.33)), vec3(0.0),
                   vec3(0.1, 0.08, 0.07) * 0.7);
  //if (d4 < res.x)
  //  res = vec2(d4, 2.0);

  d = min(d4, min(d, d2));

  return d;
}

float sleg(in vec3 p, in vec3 pa, in vec3 pb, in vec3 pc, float m, float h,
           float sc) {
  float l = sign(pa.z);

  vec2 b = sdSegment(p, pa, pb);

  float tr = 0.35 - 0.15 * smoothstep(0.0, 1.0, b.y);
  float d3 = b.x - tr * sc;

  b = sdSegment(p, pb, pc);
  tr = 0.18; // - 0.015*smoothstep(0.0,1.0,b.y);
  d3 = smin(d3, b.x - tr * sc, 0.1);

  // paw
  vec3 ww = normalize(mix(normalize(pc - pb), vec3(0.0, 1.0, 0.0), h));
  mat3 pr = base(ww);
  vec3 fc = pr * ((p - pc)) - vec3(0.02, 0.0, 0.0) * (-1.0 + 2.0 * h);
  float d4 = sdEllipsoid(fc, vec3(0.0), vec3(0.2, 0.15, 0.2));

  d3 = smin(d3, d4, 0.1);

  // nails
  float d6 = sdEllipsoid(fc, vec3(0.14, -0.04, 0.0) * (-1.0 + 2.0 * h),
                         vec3(0.1, 0.16, 0.1));
  d6 = min(d6, sdEllipsoid(vec3(fc.xy, abs(fc.z)),
                           vec3(0.13 * (-1.0 + 2.0 * h), 0.04, 0.13),
                           vec3(0.09, 0.14, 0.1)));
  d3 = smin(d3, d6, 0.001);
  return d3;

  return d3;
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
  p = p * RotMat(vec3(0.,1.,0.), -3.14/2.0);
  p += vec3(0.2,0.4,0.);
  const float scale = 0.3;
  p *= 1. / scale;
  vec3 matInfo = vec3(0);
  return mapElephant(p, matInfo) * scale * 0.9;
}

