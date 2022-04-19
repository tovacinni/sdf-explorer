/*
Copyright 2019 Thomas Hooper @tdhooper
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wlf3WX
*/

/******************************************************************************
 This work is a derivative of work by Thomas Hooper used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#define PI 3.14159265359

void pR(inout vec2 p, float a) { p = cos(a) * p + sin(a) * vec2(p.y, -p.x); }

vec2 pRi(vec2 p, float a) {
  pR(p, a);
  return p;
}

#define saturate(x) clamp(x, 0., 1.)

float vmax(vec2 v) { return max(v.x, v.y); }

float vmax(vec3 v) { return max(max(v.x, v.y), v.z); }

float vmin(vec3 v) { return min(min(v.x, v.y), v.z); }

float vmin(vec2 v) { return min(v.x, v.y); }

float fBox(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fCorner2(vec2 p) {
  return length(max(p, vec2(0))) + vmax(min(p, vec2(0)));
}

float fDisc(vec3 p, float r) {
  float l = length(p.xz) - r;
  return l < 0. ? abs(p.y) : length(vec2(p.y, l));
}

float fHalfCapsule(vec3 p, float r) {
  return mix(length(p.xz) - r, length(p) - r, step(0., p.y));
}

// IQ https://www.shadertoy.com/view/Xds3zN
float sdRoundCone(in vec3 p, in float r1, float r2, float h) {
  vec2 q = vec2(length(p.xz), p.y);

  float b = (r1 - r2) / h;
  float a = sqrt(1.0 - b * b);
  float k = dot(q, vec2(-b, a));

  if (k < 0.0)
    return length(q) - r1;
  if (k > a * h)
    return length(q - vec2(0.0, h)) - r2;

  return dot(q, vec2(a, b)) - r1;
}

float smin2(float a, float b, float r) {
  vec2 u = max(vec2(r - a, r - b), vec2(0));
  return max(r, min(a, b)) - length(u);
}

float smax2(float a, float b, float r) {
  vec2 u = max(vec2(r + a, r + b), vec2(0));
  return min(-r, max(a, b)) + length(u);
}

float smin(float a, float b, float k) {
  float f = clamp(0.5 + 0.5 * ((a - b) / k), 0., 1.);
  return (1. - f) * a + f * b - f * (1. - f) * k;
}

float smax(float a, float b, float k) { return -smin(-a, -b, k); }

float smin3(float a, float b, float k) {
  return min(smin(a, b, k), smin2(a, b, k));
}

float smax3(float a, float b, float k) {
  return max(smax(a, b, k), smax2(a, b, k));
}

float ellip(vec3 p, vec3 s) {
  float r = vmin(s);
  p *= r / s;
  return length(p) - r;
}

float ellip(vec2 p, vec2 s) {
  float r = vmin(s);
  p *= r / s;
  return length(p) - r;
}

bool isEye = false;

float mHead(vec3 p) {

  pR(p.yz, -.1);
  p.y -= .11;

  vec3 pa = p;
  p.x = abs(p.x);
  vec3 pp = p;

  float d = 1e12;

  // skull back
  p += vec3(0, -.135, .09);
  d = ellip(p, vec3(.395, .385, .395));

  // skull base
  p = pp;
  p += vec3(0, -.135, .09) + vec3(0, .1, .07);
  d = smin(d, ellip(p, vec3(.38, .36, .35)), .05);

  // forehead
  p = pp;
  p += vec3(0, -.145, -.175);
  d = smin(d, ellip(p, vec3(.315, .3, .33)), .18);

  p = pp;
  pR(p.yz, -.5);
  float bb = fBox(p, vec3(.5, .67, .7));
  d = smax(d, bb, .2);

  // face base
  p = pp;
  p += vec3(0, .25, -.13);
  d = smin(d, length(p) - .28, .1);

  // behind ear
  p = pp;
  p += vec3(-.15, .13, .06);
  d = smin(d, ellip(p, vec3(.15, .15, .15)), .15);

  p = pp;
  p += vec3(-.07, .18, .1);
  d = smin(d, length(p) - .2, .18);

  // cheek base
  p = pp;
  p += vec3(-.2, .12, -.14);
  d = smin(d, ellip(p, vec3(.15, .22, .2) * .8), .15);

  // jaw base
  p = pp;
  p += vec3(0, .475, -.16);
  pR(p.yz, .8);
  d = smin(d, ellip(p, vec3(.19, .1, .2)), .1);

  // brow
  p = pp;
  p += vec3(0, -.0, -.18);
  vec3 bp = p;
  float brow = fHalfCapsule(p * vec3(.65, 1, .9), .27);
  brow = length(p) - .36;
  p.x -= .37;
  brow = smax(brow, dot(p, normalize(vec3(1, .2, -.2))), .2);
  p = bp;
  brow = smax(brow, dot(p, normalize(vec3(0, .6, 1))) - .43, .25);
  p = bp;
  pR(p.yz, -.5);
  float peak = -p.y - .165;
  peak += smoothstep(.0, .2, p.x) * .01;
  peak -= smoothstep(.12, .29, p.x) * .025;
  brow = smax(brow, peak, .07);
  p = bp;
  pR(p.yz, .5);
  brow = smax(brow, -p.y - .06, .15);
  d = smin(d, brow, .06);

  // nose
  p = pp;
  p += vec3(0, .03, -.45);
  pR(p.yz, 3.);
  d = smin(d, sdRoundCone(p, .008, .05, .18), .1);

  p = pp;
  p += vec3(0, .06, -.47);
  pR(p.yz, 2.77);
  d = smin(d, sdRoundCone(p, .005, .04, .225), .05);

  // jaw

  p = pp;
  vec3 jo = vec3(-.25, .4, -.07);
  p = pp + jo;
  float jaw = dot(p, normalize(vec3(1, -.2, -.05))) - .069;
  jaw = smax(jaw, dot(p, normalize(vec3(.5, -.25, .35))) - .13, .12);
  jaw = smax(jaw, dot(p, normalize(vec3(-.0, -1., -.8))) - .12, .15);
  jaw = smax(jaw, dot(p, normalize(vec3(.98, -1., .15))) - .13, .08);
  jaw = smax(jaw, dot(p, normalize(vec3(.6, -.2, -.45))) - .19, .15);
  jaw = smax(jaw, dot(p, normalize(vec3(.5, .1, -.5))) - .26, .15);
  jaw = smax(jaw, dot(p, normalize(vec3(1, .2, -.3))) - .22, .15);

  p = pp;
  p += vec3(0, .63, -.2);
  pR(p.yz, .15);
  float cr = .5;
  jaw = smax(jaw, length(p.xy - vec2(0, cr)) - cr, .05);

  p = pp + jo;
  jaw = smax(jaw, dot(p, normalize(vec3(0, -.4, 1))) - .35, .1);
  jaw = smax(jaw, dot(p, normalize(vec3(0, 1.5, 2))) - .3, .2);
  jaw = max(jaw, length(pp + vec3(0, .6, -.3)) - .7);

  p = pa;
  p += vec3(.2, .5, -.1);
  float jb = length(p);
  jb = smoothstep(.0, .4, jb);
  float js = mix(0., -.005, jb);
  jb = mix(.01, .04, jb);

  d = smin(d, jaw - js, jb);

  // chin
  p = pp;
  p += vec3(0, .585, -.395);
  p.x *= .7;
  d = smin(d, ellip(p, vec3(.028, .028, .028) * 1.2), .15);

  // cheek

  p = pp;
  p += vec3(-.2, .2, -.28);
  pR(p.xz, .5);
  pR(p.yz, .4);
  float ch = ellip(p, vec3(.1, .1, .12) * 1.05);
  d = smin(d, ch, .1);

  p = pp;
  p += vec3(-.26, .02, -.1);
  pR(p.xz, .13);
  pR(p.yz, .5);
  float temple = ellip(p, vec3(.1, .1, .15));
  temple = smax(temple, p.x - .07, .1);
  d = smin(d, temple, .1);

  p = pp;
  p += vec3(.0, .2, -.32);
  ch = ellip(p, vec3(.1, .08, .1));
  d = smin(d, ch, .1);

  p = pp;
  p += vec3(-.17, .31, -.17);
  ch = ellip(p, vec3(.1));
  d = smin(d, ch, .1);

  // mouth base
  p = pp;
  p += vec3(-.0, .29, -.29);
  pR(p.yz, -.3);
  d = smin(d, ellip(p, vec3(.13, .15, .1)), .18);

  p = pp;
  p += vec3(0, .37, -.4);
  d = smin(d, ellip(p, vec3(.03, .03, .02) * .5), .1);

  p = pp;
  p += vec3(-.09, .37, -.31);
  d = smin(d, ellip(p, vec3(.04)), .18);

  // bottom lip
  p = pp;
  p += vec3(0, .455, -.455);
  p.z += smoothstep(.0, .2, p.x) * .05;
  float lb = mix(.035, .03, smoothstep(.05, .15, length(p)));
  vec3 ls = vec3(.055, .028, .022) * 1.25;
  float w = .192;
  vec2 pl2 = vec2(p.x, length(p.yz * vec2(.79, 1)));
  float bottomlip = length(pl2 + vec2(0, w - ls.z)) - w;
  bottomlip = smax(bottomlip, length(pl2 - vec2(0, w - ls.z)) - w, .055);
  d = smin(d, bottomlip, lb);

  // top lip
  p = pp;
  p += vec3(0, .38, -.45);
  pR(p.xz, -.3);
  ls = vec3(.065, .03, .05);
  w = ls.x * (-log(ls.y / ls.x) + 1.);
  vec3 pl = p * vec3(.78, 1, 1);
  float toplip = length(pl + vec3(0, w - ls.y, 0)) - w;
  toplip = smax(toplip, length(pl - vec3(0, w - ls.y, 0)) - w, .065);
  p = pp;
  p += vec3(0, .33, -.45);
  pR(p.yz, .7);
  float cut;
  cut = dot(p, normalize(vec3(.5, .25, 0))) - .056;
  float dip = smin(dot(p, normalize(vec3(-.5, .5, 0))) + .005,
                   dot(p, normalize(vec3(.5, .5, 0))) + .005, .025);
  cut = smax(cut, dip, .04);
  cut = smax(cut, p.x - .1, .05);
  toplip = smax(toplip, cut, .02);

  d = smin(d, toplip, .07);

  // seam
  p = pp;
  p += vec3(0, .425, -.44);
  lb = length(p);
  float lr = mix(.04, .02, smoothstep(.05, .12, lb));
  pR(p.yz, .1);
  p.y -= smoothstep(0., .03, p.x) * .002;
  p.y += smoothstep(.03, .1, p.x) * .007;
  p.z -= .133;
  float seam = fDisc(p, .2);
  seam = smax(seam, -d - .015, .01); // fix inside shape
  d = mix(d, smax(d, -seam, lr), .65);

  // nostrils base
  p = pp;
  p += vec3(0, .3, -.43);
  d = smin(d, length(p) - .05, .07);

  // nostrils
  p = pp;
  p += vec3(0, .27, -.52);
  pR(p.yz, .2);
  float nostrils = ellip(p, vec3(.055, .05, .06));

  p = pp;
  p += vec3(-.043, .28, -.48);
  pR(p.xy, .15);
  p.z *= .8;
  nostrils = smin(nostrils, sdRoundCone(p, .042, .0, .12), .02);

  d = smin(d, nostrils, .02);

  p = pp;
  p += vec3(-.033, .3, -.515);
  pR(p.xz, .5);
  d = smax(d, -ellip(p, vec3(.011, .03, .025)), .015);

  // return d;

  // eyelids
  p = pp;
  p += vec3(-.16, .07, -.34);
  float eyelids = ellip(p, vec3(.08, .1, .1));

  p = pp;
  p += vec3(-.16, .09, -.35);
  float eyelids2 = ellip(p, vec3(.09, .1, .07));

  // edge top
  p = pp;
  p += vec3(-.173, .148, -.43);
  p.x *= .97;
  float et = length(p.xy) - .09;

  // edge bottom
  p = pp;
  p += vec3(-.168, .105, -.43);
  p.x *= .9;
  float eb = dot(p, normalize(vec3(-.1, -1, -.2))) + .001;
  eb = smin(eb, dot(p, normalize(vec3(-.3, -1, 0))) - .006, .01);
  eb = smax(eb, dot(p, normalize(vec3(.5, -1, -.5))) - .018, .05);

  float edge = max(max(eb, et), -d);

  d = smin(d, eyelids, .01);
  d = smin(d, eyelids2, .03);
  d = smax(d, -edge, .005);

  // eyeball
  p = pp;
  p += vec3(-.165, .0715, -.346);
  float eyeball = length(p) - .088;
  isEye = eyeball < d;
  d = min(d, eyeball);

  // tear duct
  p = pp;
  p += vec3(-.075, .1, -.37);
  d = min(d, length(p) - .05);

  // ear
  p = pp;
  p += vec3(-.405, .12, .10);
  pR(p.xy, -.12);
  pR(p.xz, .35);
  pR(p.yz, -.3);
  vec3 pe = p;

  // base
  float ear = p.s + smoothstep(-.05, .1, p.y) * .015 - .005;
  float earback = -ear - mix(.001, .025, smoothstep(.3, -.2, p.y));

  // inner
  pR(p.xz, -.5);
  float iear = ellip(p.zy - vec2(.01, -.03), vec2(.045, .05));
  iear = smin(iear, length(p.zy - vec2(.04, -.09)) - .02, .09);
  float ridge = iear;
  iear = smin(iear, length(p.zy - vec2(.1, -.03)) - .06, .07);
  ear = smax2(ear, -iear, .04);
  earback = smin(earback, iear - .04, .02);

  // ridge
  p = pe;
  pR(p.xz, .2);
  ridge = ellip(p.zy - vec2(.01, -.03), vec2(.045, .055));
  ridge = smin3(ridge, -pRi(p.zy, .2).x - .01, .015);
  ridge = smax3(ridge, -ellip(p.zy - vec2(-.01, .1), vec2(.12, .08)), .02);

  float ridger = .01;

  ridge = max(-ridge, ridge - ridger);

  ridge = smax2(ridge, abs(p.x) - ridger / 2., ridger / 2.);

  ear = smin(ear, ridge, .045);

  p = pe;

  // outline
  float outline = ellip(pRi(p.yz, .2), vec2(.12, .09));
  outline = smin(outline, ellip(p.yz + vec2(.155, -.02), vec2(.035, .03)), .14);

  // edge
  float eedge = p.x + smoothstep(.2, -.4, p.y) * .06 - .03;

  float edgeo = ellip(pRi(p.yz, .1), vec2(.095, .065));
  edgeo = smin(edgeo, length(p.zy - vec2(0, -.1)) - .03, .1);
  float edgeoin = smax(abs(pRi(p.zy, .15).y + .035) - .01, -p.z - .01, .01);
  edgeo = smax(edgeo, -edgeoin, .05);

  float eedent = smoothstep(-.05, .05, -p.z) *
                 smoothstep(.06, 0., fCorner2(vec2(-p.z, p.y)));
  eedent += smoothstep(.1, -.1, -p.z) * .2;
  eedent += smoothstep(.1, -.1, p.y) * smoothstep(-.03, .0, p.z) * .3;
  eedent = min(eedent, 1.);

  eedge += eedent * .06;

  eedge = smax(eedge, -edgeo, .01);
  ear = smin(ear, eedge, .01);
  ear = max(ear, earback);

  ear = smax2(ear, outline, .015);

  d = smin(d, ear, .015);

  // targus
  p = pp;
  p += vec3(-.34, .2, .02);
  d = smin2(d, ellip(p, vec3(.015, .025, .015)), .035);
  p = pp;
  p += vec3(-.37, .18, .03);
  pR(p.xz, .5);
  pR(p.yz, -.4);
  d = smin(d, ellip(p, vec3(.01, .03, .015)), .015);

  return d;
}

float sstep(float t) { return sin(t * PI - PI / 2.) * .5 + .5; }

float sdf(vec3 p) {

  float scale = 1.;
  p /= scale;
  return mHead(p) * scale;
}
