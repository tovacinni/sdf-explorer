/*
Copyright 2013 Antonalog @Antonalog
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ldX3RX
*/

/******************************************************************************
 This work is a derivative of work by Antonalog used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#define pi 3.1415927

// various primitives, thanks IQ!
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float Sphere(vec3 p, vec3 c, float r) { return length(p - c) - r; }

float Box(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float BevelBox(vec3 p, vec3 size, float box_r) {
  vec3 box_edge = size - box_r * 0.5;
  vec3 dd = abs(p) - box_edge;

  // in (dd -ve)
  float maxdd = max(max(dd.x, dd.y), dd.z);
  // 0 away result if outside
  maxdd = min(maxdd, 0.0);

  // out (+ve);
  dd = max(dd, 0.0);
  float ddd = (length(dd) - box_r);

  // combine the in & out cases
  ddd += maxdd;
  return ddd;
}

float CylinderXY(vec3 p, vec3 c) { return length(p.xy - c.xy) - c.z; }

float CylinderXZ(vec3 p, vec3 c) { return length(p.xz - c.xy) - c.z; }

float CylinderYZ(vec3 p, vec3 c) { return length(p.yz - c.xy) - c.z; }

float udHexPrism(vec2 p, float h) {
  vec2 q = abs(p);
  return max(q.x + q.y * 0.57735, q.y * 1.1547) - h;
}

vec3 RotX(vec3 p, float t) {
  float c = cos(t);
  float s = sin(t);
  return vec3(p.x, p.y * c + p.z * s, -p.y * s + p.z * c);
}

vec3 RotY(vec3 p, float t) {
  float c = cos(t);
  float s = sin(t);
  return vec3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

vec3 RotZ(vec3 p, float t) {
  float c = cos(t);
  float s = sin(t);
  return vec3(p.x * c + p.y * s, -p.x * s + p.y * c, p.z);
}

// initiate time corridor... (aka begin original work)

float Plate(vec3 p, float h) {
  p = RotX(p, -pi * 0.0625);

  float hh = 0.25;
  float w = 0.5 * hh;
  float bev = 0.02;

  float base = BevelBox(p - vec3(0.0, 0.0, 0), vec3(w, h, w), bev);
  float scallop = BevelBox(RotX(p, -pi * 0.0625) - vec3(0., -.6 * h, 0.6 * hh),
                           vec3(w, 2. * h, w) * 0.5, bev);
  base = max(base, -scallop);

  float hole_size = 0.03;
  float hole_off = h * 0.8;

  vec3 reflect_y_p = vec3(p.x, abs(p.y), p.z);

  //    float hole = CylinderXY( reflect_y_p, vec3(0.,hole_off,hole_size));
  //    base = max(base,-hole);

  float rivet = Sphere(reflect_y_p, vec3(0., hole_off, w), hole_size);

  base = min(base, rivet);
  return base;
}

float PlateRing(vec3 p, float polar_t, float polar_r) {
  float h = abs(polar_t) < pi * (3.0 / 8.) ? 0.25 : 0.5;

  polar_t = mod(polar_t, pi * (1. / 8.)) - pi * (1. / 8.) * 0.5;
  vec3 q = vec3(polar_r * sin(polar_t), p.y, polar_r * cos(polar_t));
  q -= vec3(0., -(h - 0.25), 1.0);

  return Plate(q, h);
}

float Whisk(vec3 p) {
  p = abs(p);
  float r = 0.075;
  float c = min(0.4 - p.x, 0.1) * r * 12.0;
  return length(p.zy - vec2(c, c)) - r * 0.25;
}

float Gun(vec3 p) {
  p -= vec3(1.7, -.55, -0.70);

  float d = Whisk(p);
  d = min(d, Whisk(RotX(p, pi * 0.25)));
  float barrel = length(p.zy) - 0.05;

  barrel = max(barrel, abs(p.x) - 0.5); // clip

  barrel = max(barrel, -(length(p.zy) - 0.025));
  return min(d, barrel);
}

const float suck_end = 1.0;

float Plunger(vec3 p) {
  p -= vec3(1.7, -.55, 0.70);
  float barrel = length(p.zy) - 0.075;
  barrel = max(barrel, abs(p.x) - 0.75); // clip!

  float sucker = Sphere(p, vec3(suck_end, 0.0, 0.0), 0.3);
  sucker = max(sucker, -Sphere(p, vec3(suck_end, 0.0, 0.0), 0.25));
  sucker = max(sucker, p.x - 0.9); // clip
  return min(barrel, sucker);
}

float GunPort(vec3 p) {
  p.z = abs(p.z);

  float w = 0.225;
  float d = 0.5;

  vec3 c = vec3(.75 - 0.25, -.55, 0.70);

  float s = Sphere(p, c + vec3(.35 + 0.25, 0, 0), w * 0.66);

  p.x += 0.2 * p.y;
  float bev = 0.02;
  float b = BevelBox(p - c, vec3(d, w, w), bev);

  return min(b, s);
}

float DarkBits(vec3 p) {
  // core body
  float b = CylinderXZ(p, vec3(0., 0., 0.8 - 0.15 * p.y));
  b = max(b, abs(p.y) - 1.2); // clip!

  // sucker
  vec3 sucker_p = p - vec3(1.7, -.55, 0.70);
  float sucker = Sphere(sucker_p, vec3(suck_end, 0.0, 0.0), 0.3);

  // bulb
  vec3 stalk_p = RotZ(p, pi * 0.05);
  float bulb_d = Sphere(stalk_p, vec3(2.4, 1.1, 0.0), 0.2);
  bulb_d = max(bulb_d, stalk_p.x - 2.5); // clip

  // gun ports
  p.z = abs(p.z);

  float w = 0.225;
  float d = 0.5;

  vec3 c = vec3(.75 - 0.25, -.55, 0.70);

  float s = Sphere(p, c + vec3(.35 + 0.25, 0, 0), w * 0.66);

  return min(min(bulb_d, s), min(b, sucker));
}

float Balls(vec3 p, float polar_t, float polar_r) {
  p.y += 2.45;

  float ang_reps = 6.;
  polar_t = mod(polar_t, pi * (1. / ang_reps)) - pi * (1. / ang_reps) * 0.5;
  vec3 q = vec3(polar_r * sin(polar_t), p.y, polar_r * cos(polar_t));

  float k = .5;
  q.y = mod(q.y, k) - 0.5 * k;

  float balls = Sphere(q, vec3(0.0, 0, 1.25 - 0.1 * floor(p.y * 2.)), 0.2);

  balls = max(balls, abs(p.y) - 1.); // clip!
  return balls;
}

float Body(vec3 p) {
  vec3 q = p;
  p = RotY(p, pi * 1.0 / 12.0);
  float taper = 1.0 + 0.1 * p.y;

  taper -= p.y < -3.5 ? .2 * clamp(-(p.y + 3.5), 0., 0.1) : 0.;
  p.xz *= taper;

  float w = 1.15; /// taper;
  float d = udHexPrism(p.zx, w);
  d = max(d, udHexPrism(p.xz, w));

  d /= taper;

  q.y += +2.45;

  d = max(d, abs(q.y) - 1.5); // clip!
  return d;
}

float Belt(vec3 p, float polar_t, float polar_r) {

  // belt
  float r = p.y + 1.05;
  float d = CylinderXZ(p, vec3(0., 0., 1.25 - 0.15 * r));
  vec3 q = p;
  q.y += 1.05;
  d = max(d, abs(q.y) - 0.125); // clip!

  // core body
  float b = CylinderXZ(p, vec3(0., 0., 0.8 - 0.15 * p.y));
  b = max(b, abs(p.y) - 1.2); // clip!

  // buckle
  d = min(d, BevelBox(p + vec3(-0.8, 0.60, 0.), vec3(.2, .2, .4 + 0.2 * p.y),
                      0.05));

  d = min(d, b);
  return d;
}

float Grill(vec3 p, float polar_t, float polar_r) {
  p += vec3(0., -0.5, 0.);

  vec3 c = p;
  float k = .25;
  c.y = mod(c.y + 0.1, k) - 0.5 * k;

  float b = CylinderXZ(c, vec3(0., 0., 0.9));
  b = max(b, abs(c.y) - 0.025); // clip each ring

  b = max(b, abs(p.y) - 0.5); // clip the repetitions

  float ang_reps = 4.;
  polar_t = mod(polar_t, pi * (1. / ang_reps)) - pi * (1. / ang_reps) * 0.5;
  vec3 q = vec3(polar_r * cos(polar_t), p.y, polar_r * sin(polar_t));

  q = RotZ(q, pi * 0.06);

  float d = BevelBox(q, vec3(0.8, 0.5, .05), .045);
  return min(d, b);
}

float Head(vec3 p) {
  float d = Sphere(p, vec3(0., 0.66, 0.), 1.0);
  d = max(d, -p.y + 1.0); // clip!
  return d;
}

float Eye(vec3 p) {
  // stalk
  p = RotZ(p, pi * 0.05);
  float d = CylinderYZ(p, vec3(1.1, 0., 0.1));
  d = max(d, -p.x); // clip

  // bulb
  d = min(d, Sphere(p, vec3(2.4, 1.1, 0.0), 0.2));

  d = max(d, p.x - 2.5); // clip

  // lens
  d = min(d, Sphere(p, vec3(2.4, 1.1, 0.0), 0.15));

  // mount
  d = min(d, BevelBox(p + vec3(-0.9, -1.1, 0.), vec3(.2, .2, .4 - 0.2 * p.y),
                      0.05));
  return d;
}

float Lens(vec3 p) {
  p = RotZ(p, pi * 0.05);
  return Sphere(p, vec3(2.4, 1.1, 0.0), 0.15);
}

float Ears(vec3 p) {
  p.z = abs(p.z);

  p = RotX(p, -pi * 0.25);

  float d = CylinderXY(p, vec3(0.0, .5, 0.2 - 0.1 * (p.z - 0.5)));

  d = max(d, p.z - 1.75); // clip

  return d;
}

float floor_height = -4.0;

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

float dalek(vec3 p) {
  float polar_t = atan(p.z, p.x);
  float polar_r = length(p.xz);

  float d = 1e10;
  float d_bound = 2.5;
  if (polar_r <
      d_bound) // optimize away this stuff if far away from bound cylinder
  {
    //  if (p.y < -1.0) //opt?
    d = min(d, Balls(p, polar_t, polar_r));

    d = min(d, Belt(p, polar_t, polar_r));

    d = min(d, PlateRing(p, polar_t, polar_r));

    //  if (p.y > 0.25) //opt?
    {
      d = min(d, Grill(p, polar_t, polar_r));
      d = min(d, Head(p));
      d = min(d, Ears(p));
    }
  }

  //    if (p.y < -1.0) //opt ?
  d = min(d, Body(p));
  //    else            //opt ? glitches shadows though
  if (abs(polar_t) <
      pi * 0.5) // optimize away this stuff if far away from front
  {
    d = min(d, Eye(p));
    d = min(d, GunPort(p));
    d = min(d, Gun(p));
    d = min(d, Plunger(p));
  }

  return d;
}

float sdf(vec3 p) {
  p = p * RotMat(vec3(0.,1.,0.), 3.14/2.0);
  p += vec3(0.,-0.2,0.);
  const float scale = 0.25;
  p *= 1. / scale;
  return dalek(p) * scale * 0.5;
}
