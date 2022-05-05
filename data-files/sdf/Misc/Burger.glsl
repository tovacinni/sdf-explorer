/*
Copyright 2019 Xor @XorDev
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/WsXSDH
*/

/******************************************************************************
 This work is a derivative of work by XorDev used under CC BY-NC-SA 3.0.
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

float soft(float a, float b, float n) {
  return log(exp(a * n) + exp(b * n)) / n;
}

vec3 hash(vec3 p) {
  return fract(sin(p * mat3(45.32, 32.42, -41.55, 65.35, -43.42, 51.55, 45.32,
                            29.82, -41.45)) *
               vec3(142.83, 253.36, 188.64));
}

vec3 value(vec3 p) {
  vec3 f = floor(p);
  vec3 s = p - f;
  s *= s * (3. - s - s);
  const vec2 o = vec2(0, 1);

  return mix(mix(mix(hash(f + o.xxx), hash(f + o.yxx), s.x),
                 mix(hash(f + o.xyx), hash(f + o.yyx), s.x), s.y),
             mix(mix(hash(f + o.xxy), hash(f + o.yxy), s.x),
                 mix(hash(f + o.xyy), hash(f + o.yyy), s.x), s.y),
             s.z);
}

float worley(vec3 p) {
  float d = 1.;
  for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++)
      for (int z = -1; z <= 1; z++) {
        vec3 f = floor(p + vec3(x, y, z));
        vec3 v = p - f - hash(f);
        d = soft(d, dot(v, v), -6.);
      }
  return d;
}

float seed(vec3 p) {
  float d = 1.;
  for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++) {
      vec3 f = floor(vec3(p.xy, 0) + vec3(x, y, 0));
      vec3 h = hash(f) * vec3(1, 1, 63);
      vec3 v = mat3(cos(h.z), sin(h.z), 0, sin(h.z), -cos(h.z), 0, 0, 0, 1) *
               (p - f - h * .9) * vec3(1.7, 1, 0);
      d = min(d, dot(v, v) + step(9., length(f + .6)) + step(p.z, 2.));
    }
  return max(.05 - d, 0.);
}

float cheese(vec3 p) {
  p.z += -.27 + .03 * p.x * p.x + .1 * soft(dot(p.xy, p.xy) - 3.5, 0., 10.);
  return(length(max(abs(p) - vec3(1.6, 1.6, 0), 0.)) - .02) * .8;
}

float model(vec3 p) {
  float d = length(p) - 2.5;
  float m = soft(length(p.xy) - 3.,
                 pow(p.z - soft(d, 0., 20.) * .7 + 1.1, 2.) - .01, 10.);

  if (d < .1) {
    vec3 c = vec3(p.xy, max(p.z - .35, 0.) * 1.6);
    float b = soft(length(c + .05 * sin(c.yzx * 2.)) * .6 - 1.15,
                   .41 - abs(p.z + .15) - .02 * c.x * c.x, 40.);
    m = min(m, soft(b, -1. - p.z, 20.));
    m = min(m, soft(length(p.xy + .1 * sin(c.yx * 2.)) - 2.1,
                    pow(p.z - .03 + .03 * p.x * p.x, 2.) - .04, 12.));
    m = min(m,
            soft(length(p) - 1.9, abs(p.z + .4 - .03 * p.y * p.y) - .1, 80.));
    m = min(m, cheese(p));
    vec3 r = value(p / dot(p, p) * vec3(14, 14, 1)) - .5;
    vec3 l = p + vec3(0, 0, .46) +
             vec3(0, 0, length(p.xy) - 1.8) * .3 * cos(r.x * 5. - r.y * 5.);
    m = min(m, soft(length(l) - 2.1 - .4 * r.z, abs(l.z) - .02, 28.) * .8);

    float s = .2 * seed(p * 5.);
    return m - s;
  }
  return min(d, m);
}

float sdf(vec3 p) {
  const float scale = 0.3;
  p *= 1. / scale;
  return model(p * RotMat(vec3(1., 0., 0.), pi / 2.)) * scale;
}
