/*
Copyright 2013 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/MsXGWr
Archive Link: https://web.archive.org/web/20191113080801/https://www.shadertoy.com/view/MsXGWr
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

//----------------------------------------------------------------

vec2 sdSegment(vec3 a, vec3 b, vec3 p) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return vec2(length(pa - ba * h), h);
}

float sdEllipsoid(in vec3 p, in vec3 r) {
  return (length(p / r) - 1.0) * min(min(r.x, r.y), r.z);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float opS(float d1, float d2) { return max(-d1, d2); }

//----------------------------------------------------------------

vec2 map(vec3 p) {
  p.y -= 1.8;

  p.x = abs(p.x);

  vec3 q = p;
  q.y -= 0.3 * pow(1.0 - length(p.xz), 1.0) * smoothstep(0.0, 0.2, p.y);
  q.y *= 1.05;
  q.z *= 1.0 + 0.1 * smoothstep(0.0, 0.5, q.z) * smoothstep(-0.5, 0.5, p.y);
  float dd = length((p - vec3(0.0, 0.65, 0.8)) * vec3(1.0, 0.75, 1.0));
  float am = clamp(4.0 * abs(p.y - 0.45), 0.0, 1.0);
  float fo = -0.03 * (1.0 - smoothstep(0.0, 0.04 * am, abs(dd - 0.42))) * am;
  float dd2 = length((p - vec3(0.0, 0.65, 0.8)) * vec3(1.0, 0.25, 1.0));
  float am2 = clamp(1.5 * (p.y - 0.45), 0.0, 1.0);
  float fo2 =
      -0.085 * (1.0 - smoothstep(0.0, 0.08 * am2, abs(dd2 - 0.42))) * am2;
  q.y += -0.05 + 0.05 * length(q.x);

  float d1 = length(q) - 0.9 + fo + fo2;
  vec2 res = vec2(d1, 1.0);

  // arms
  vec2 h = sdSegment(vec3(.83, 0.15, 0.0), vec3(1.02, -0.6, -.1), p);
  float d2 = h.x - 0.07;
  res.x = smin(res.x, d2, 0.03);
  h = sdSegment(vec3(1.02, -0.6, -.1), vec3(0.95, -1.2, 0.1), p);
  d2 = h.x - 0.07 + h.y * 0.02;
  res.x = smin(res.x, d2, 0.06);

  // hands
  if (p.y < -1.0) {
    float fa = sin(3.0);
    h = sdSegment(vec3(0.95, -1.2, 0.1), vec3(0.97, -1.5, 0.0), p);
    d2 = h.x - 0.03;
    res.x = smin(res.x, d2, 0.01);
    h = sdSegment(vec3(0.97, -1.5, 0.0), vec3(0.95, -1.7, 0.0) - 0.01 * fa, p);
    d2 = h.x - 0.03 + 0.01 * h.y;
    res.x = smin(res.x, d2, 0.02);
    h = sdSegment(vec3(0.95, -1.2, 0.1), vec3(1.05, -1.5, 0.1), p);
    d2 = h.x - 0.03;
    res.x = smin(res.x, d2, 0.02);
    h = sdSegment(vec3(1.05, -1.5, 0.1), vec3(1.0, -1.75, 0.1) - 0.01 * fa, p);
    d2 = h.x - 0.03 + 0.01 * h.y;
    res.x = smin(res.x, d2, 0.02);
    h = sdSegment(vec3(0.95, -1.2, 0.1), vec3(0.98, -1.5, 0.2), p);
    d2 = h.x - 0.03;
    res.x = smin(res.x, d2, 0.03);
    h = sdSegment(vec3(0.98, -1.5, 0.2), vec3(0.95, -1.7, 0.15) - 0.01 * fa, p);
    d2 = h.x - 0.03 + 0.01 * h.y;
    res.x = smin(res.x, d2, 0.03);
    h = sdSegment(vec3(0.95, -1.2, 0.1), vec3(0.85, -1.4, 0.2), p);
    d2 = h.x - 0.04 + 0.01 * h.y;
    res.x = smin(res.x, d2, 0.05);
    h = sdSegment(vec3(0.85, -1.4, 0.2), vec3(0.85, -1.63, 0.15) + 0.01 * fa,
                  p);
    d2 = h.x - 0.03 + 0.01 * h.y;
    res.x = smin(res.x, d2, 0.03);
  }

  // legs
  if (p.y < 0.0) {
    h = sdSegment(vec3(0.5, -0.5, 0.0), vec3(0.6, -1.2, 0.1), p);
    d2 = h.x - 0.14 + h.y * 0.08;
    res.x = smin(res.x, d2, 0.06);
    h = sdSegment(vec3(0.6, -1.2, 0.1), vec3(0.5, -1.8, 0.0), p);
    d2 = h.x - 0.06;
    res.x = smin(res.x, d2, 0.06);
  }

  // feet
  if (p.y < -1.5) {
    h = sdSegment(vec3(0.5, -1.8, 0.0), vec3(0.6, -1.8, 0.4), p);
    d2 = h.x - 0.09 + 0.02 * h.y;
    res.x = smin(res.x, d2, 0.06);
    h = sdSegment(vec3(0.5, -1.8, 0.0), vec3(0.77, -1.8, 0.35), p);
    d2 = h.x - 0.08 + 0.02 * h.y;
    res.x = smin(res.x, d2, 0.06);
    h = sdSegment(vec3(0.5, -1.8, 0.0), vec3(0.9, -1.8, 0.2), p);
    d2 = h.x - 0.07 + 0.02 * h.y;
    res.x = smin(res.x, d2, 0.06);
  }

  // horns
  vec3 hp = p - vec3(0.25, 0.7, 0.0);
  hp.xy = mat2(0.6, 0.8, -0.8, 0.6) * hp.xy;
  hp.x += 0.8 * hp.y * hp.y;
  float d4 = sdEllipsoid(hp, vec3(0.13, 0.5, 0.16));
  // d4 *= 0.9;
  if (d4 < res.x)
    res = vec2(d4, 3.0);

  // eyes
  float d3 = length((p - vec3(0.0, 0.25, 0.35)) * vec3(1.0, 0.8, 1.0)) - 0.5;
  if (d3 < res.x)
    res = vec2(d3, 2.0);

  // mouth
  float mo = length((q - vec3(0.0, -0.35, 1.0)) * vec3(1.0, 1.2, 0.25) / 1.2) -
             0.3 / 1.2;
  float of = 0.1 * pow(smoothstep(0.0, 0.2, abs(p.x - 0.3)), 0.5);
  mo = max(mo, -q.y - 0.35 - of);

  float li =
      smoothstep(0.0, 0.05, mo + 0.02) - smoothstep(0.05, 0.10, mo + 0.02);
  res.x -= 0.03 * li * clamp((-q.y - 0.4) * 10.0, 0.0, 1.0);

  if (-mo > res.x)
    res = vec2(-mo, 4.0);

  res.x += 0.01 * (smoothstep(0.0, 0.05, mo + 0.062) -
                   smoothstep(0.05, 0.10, mo + 0.062));

  // teeth
  if (p.x < 0.3) {
    p.x = mod(p.x, 0.16) - 0.08;
    float d5 =
        length((p - vec3(0.0, -0.37, 0.65)) * vec3(1.0, 2.0, 1.0)) - 0.08;
    if (d5 < res.x)
      res = vec2(d5, 2.0);
  }

  return vec2(res.x * 0.8, res.y);
}

float sdf(vec3 p) {
  p += vec3(0.,0.5,0.);
  const float scale = 0.4;
  p *= 1. / scale;
  return map(p).x * scale;
}
