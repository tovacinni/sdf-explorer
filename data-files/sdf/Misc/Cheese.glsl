/*
Copyright 2018 Felipe Alfonso @bitnenfer
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/3dfGzr
*/

/******************************************************************************
 This work is a derivative of work by Felipe Alfonso used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

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

void opRotate(inout vec2 v, float r) {
  float c = cos(r);
  float s = sin(r);
  float vx = v.x * c - v.y * s;
  float vy = v.x * s + v.y * c;
  v.x = vx;
  v.y = vy;
}

vec3 opRepeate(in vec3 p, in vec3 c) { return mod(p, c) - 0.5 * c; }

float opDisp(vec3 p) {
  return sin(20.0 * p.x) * sin(20.0 * p.y) * sin(20.0 * p.z);
}

// iq's sdf functions :3
float sdBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdSphere(vec3 p, float r) { return length(p) - r; }

float sdRoundedCylinder(vec3 p, float ra, float rb, float h) {
  vec2 d = vec2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

float sdTriPrism(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float sdCappedCylinder(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float opUnion(float a, float b) {
  if (a < b) {
    return a;
  }
  return b;
}

// MAP
float mapCheese(in vec3 p) {
  float value = 0.0;
  opRotate(p.xz, 0.5);

  // base shape
  float cyl0 = sdRoundedCylinder(p, 0.30, 0.04, 0.3);
  vec3 triP0 = p + vec3(0.0, 0.0, -0.2);
  opRotate(triP0.zy, -3.14 / 2.0);
  float tri0 = sdTriPrism(triP0, vec2(.8, 0.4)) - 0.001;
  value = max(tri0, cyl0);

  // holes
  vec3 holesP = p + vec3(-0.1119641, -0.6300012, 0.1603024);
  holesP = opRepeate(holesP, vec3(0.45));
  float sp = sdSphere(holesP, 0.12);
  sp += opDisp(p * 0.3) * 0.15;
  value = max(-sp, value);

  // cut
  vec3 cutP = p + vec3(0.0, 0.0, 0.62);
  opRotate(cutP.xz, -0.4);
  opRotate(cutP.yz, -0.2);
  cutP = opRepeate(cutP, vec3(0.09, 0.001, 0.0));
  float ct = sdSphere(cutP, 0.07);

  value = max(-ct, value);

  return value;
}

float mapPlate(in vec3 p) {
  float base = sdBox(p, vec3(0.8, -0.001, 0.8)) - 0.1;
  float handle = sdBox(p + vec3(-1.0, 0.0, 0.0),
                       vec3(0.5, 0.0, 0.04 * sin(-0.1 + -p.x * 2.0))) -
                 0.1;
  return min(base, handle);
}

float mapKnife(in vec3 p) {
  p *= 0.6;
  vec3 handleP = p;
  opRotate(handleP.xy, -sin(handleP.y) * 0.5);
  opRotate(handleP.xy, 0.14);
  float handle = sdCappedCylinder(handleP, vec2(0.0, 0.24)) -
                 abs(0.05 * cos(0.3 + p.y * -4.0));
  float blade = sdBox(p + vec3(0.05, -0.6, 0.0),
                      vec3(0.1 * sqrt(abs(cos(p.y * 1.57))), 0.4, 0.002));
  return min(handle, blade);
}

float mapScene(vec3 p) {
  p = p + vec3(0.2, 0.0, 0.0);
  vec3 cheeseP = p + vec3(0.3, 0.0, -0.1);
  vec3 plateP = p + vec3(0.0, 0.456, 0.0);
  vec3 knifeP = p + vec3(-0.7742586, 0.2902968, -0.11406922);

  opRotate(knifeP.yz, 3.14 / 2.0 + 0.015);
  opRotate(knifeP.xy, -3.14 / 4.0);
  opRotate(knifeP.xz, -0.28);
  float cheese = mapCheese(cheeseP);
  float plate = mapPlate(plateP);
  float knife = mapKnife(knifeP);

  return opUnion(knife, opUnion(cheese, plate));
}

float sdf(vec3 p) {
  const float scale = 0.5;
  p *= 1. / scale;
  return mapScene(p * RotMat(vec3(0., 1., 0.), pi)) * scale;
}
