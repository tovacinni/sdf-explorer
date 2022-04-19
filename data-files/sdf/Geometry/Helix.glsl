/*
Copyright 2016 Xor @XorDev
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/Md3XRM
*/

/******************************************************************************
 This work is a derivative of work by XorDev used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

float FULL_SIZE = 2.0;
float EDGE_SIZE = 0.2;
float PAIR_SIZE = 0.2;

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

float opSmoothSubtraction(float d1, float d2, float k) {
  float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
  return mix(d2, -d1, h) + k * h * (1.0 - h);
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float model(vec3 p) {
  float A = p.z / 3.0;
  vec3 R = vec3(cos(A), sin(A), 0);
  vec3 C = vec3(p.xy + R.yx * vec2(1, -1), fract(p.z) - 0.5);

  float H = min(length(C.xy + R.xy * FULL_SIZE), length(C.xy - R.xy * FULL_SIZE)) * 0.5 - EDGE_SIZE;
  float P = max(length(vec2(dot(C.xy, R.yx * vec2(1, -1)), C.z)) - PAIR_SIZE,
                length(C.xy) - FULL_SIZE);

  float D = min(H, P);
  return D;
}

float sdf(vec3 p) {
  float boxD = sdBox(p, vec3(1.,1.,1.));
  const float scale = 0.125;
  p *= 1. / scale;
  return max(boxD, model(p * RotMat(vec3(1., 0., 0.), pi / 2.))) * scale;
}
