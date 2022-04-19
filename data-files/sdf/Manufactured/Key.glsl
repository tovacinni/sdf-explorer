/*
Copyright 2020 Flopine @Flopine
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wssBDf
*/

/******************************************************************************
 This work is a derivative of work by Flopine used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#define PI 3.141592

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }

float cyl(vec3 p, float r, float h) {
  return max(length(p.xy) - r, abs(p.z) - h);
}

float tore(vec3 p, vec2 t) {
  return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float key(vec3 p, float t) {
  float thick = t;
  float body = cyl(p.xzy, thick, 1.5);
  float encoche = tore(p.xzy + vec3(-(2. * thick), 0.05, 1.), vec2(thick, 0.1));
  float head = max(-cyl(p - vec3(0., 2.2, 0.), 0.65, thick * 1.5),
                   cyl(p - vec3(0., 2.2, 0.), 0.8, thick));
  p.y = abs(abs(p.y - 0.45) - 0.8) - 0.15;
  float ts = tore(p, vec2(thick, 0.08));

  return min(encoche, min(min(body, head), ts));
}

float SDF(vec3 p) {
  vec3 pp = p - vec3(0., 2., 0.);
  float small = 3.5;
  float thick = 0.25;
  float d = key(p, thick);
  for (int i = 0; i < 2; i++) {
    d = min(d, key(pp * small, thick) / small);
    pp.y -= 0.55;
    small *= 4.;
  }
  return d;
}

float sdf(vec3 p) {
  p += vec3(0.,.2,0.);
  const float scale = 0.3;
  p *= 1. / scale;
  return SDF(p) * scale;
}
