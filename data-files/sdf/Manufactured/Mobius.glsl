/*
Copyright 2015 Gary Warne @Shane
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/XldSDs
*/

/******************************************************************************
 This work is a derivative of work by Gary Warne used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise,
// and comes courtesy of Fabrice Neyret's "ouside the box" thinking. :)
mat2 r2(float th) {
  vec2 a = sin(vec2(1.5707963, 0) + th);
  return mat2(a, -a.y, a.x);
}

// IQ's smooth minium function.
float smin(float a, float b, float s) {

  float h = clamp(0.5 + 0.5 * (b - a) / s, 0., 1.);
  return mix(b, a, h) - h * (1.0 - h) * s;
}

// Smooth maximum, based on the function above.
float smax(float a, float b, float s) {

  float h = clamp(0.5 + 0.5 * (a - b) / s, 0., 1.);
  return mix(b, a, h) + h * (1.0 - h) * s;
}

// The Mobius object: Take an object, sweep it around in a path (circle) at
// radius R, and twist (roll) with the axial plane as you do it. Essentially,
// that's all you're doing.
//
// By the way, I've explained the process in a hurry with a "near enough is good
// enough" attitude, so if any topology experts out there spot any conceptual
// errors, mislabling, etc, feel free to let me know.
float Mobius(vec3 q) {

  //// CONSTANTS ////
  const float toroidRadius = 1.25; // The object's disc radius.
  // const float ringWidth = .15;
  const float polRot = 4. / 4.; // Poloidal rotations.
  const float ringNum =
      32.; // Number of quantized objects embedded between the rings.

  //// RAIL SECTION ////
  vec3 p = q;

  // Angle of the point on the XZ plane.
  float a = atan(p.z, p.x);

  // Angle of the point at the center of 32 (ringNum) partitioned cells.
  //
  // Partitioning the circular path into 32 (ringNum) cells - or sections, then
  // obtaining the angle of the center position of that cell. The reason you
  // want that angle is so that you can render something at the corresponding
  // position. In this case, it will be a squared-off ring looking object.
  float ia = floor(ringNum * a / 6.2831853);
  // The ".5" value for the angle of the cell center. It was something obvious
  // that I'd overlooked. Thankfully, Dr2 did not. :)
  ia = (ia + .5) / ringNum * 6.2831853;

  // Sweeping a point around a central point at a distance (toroidRadius), more
  // or less. Basically, it's the toroidal axis bit. If that's confusing,
  // looking up a toroidal\poloidal image will clear it up.
  p.xz *= r2(a);
  p.x -= toroidRadius;
  p.xy *= r2(a * polRot); // Twisting about the poloidal direction (controlled
                          // by "polRot) as we sweep.

  // The rail object. Taking the one rail, then ofsetting it along X and Y,
  // resulting in four rails. This is a neat spacial partitioning trick, and
  // worth knowing if you've never encountered it before. Basically, you're
  // taking the rail, and splitting it into two along X and Y... also along Z,
  // but since the object is contiunous along that axis, the result is four
  // rails.
  p = abs(abs(p) -
          .25); // Change this to "p = abs(p)," and you'll see what it does.

  float rail = max(max(p.x, p.y) - .07, (max(p.y - p.x, p.y + p.x) * .7071 -
                                         .075)); // Makeshift octagon.

  //// REPEAT RING SECTION ////
  // The repeat square rings. It's similar to the way in which the rails are
  // constructed, but since the object isn't continous, we need to use the
  // quantized angular positions (using "ia").
  p = q;
  // Another toroidal sweep using the quantized (partitioned, etc) angular
  // position.
  p.xz *= r2(ia); // Using the quantized angle to obtain the position of the
                  // center of the corresponding cell.
  p.x -= toroidRadius;
  p.xy *= r2(a * polRot); // Twisting about the poloidal direction - as we did
                          // with the rails.

  // Constructing some square rings.
  p = abs(p);
  float ring = max(p.x, p.y); // Square shape.
  // Square rings: A flat cube, with a thinner square pole taken out.
  ring = max(max(ring - .275, p.z - .03), -(ring - .2));

  //// WHOLE OBJECT ////
  // Object ID for shading purposes.
  // mObjID = step(ring, rail); // smoothstep(0., .07, rail - sqr);

  // Smoothly combine (just slightly) the square rings with the rails.
  return smin(ring, rail, .07);
}

float sdf(vec3 p) {
  const float scale = 0.5;
  p *= 1. / scale;
  return Mobius(p) * scale;
}
