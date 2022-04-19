/*
Copyright al13n 2014 @al13n
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/Xd2XDW
*/

/******************************************************************************
 This work is a derivative of work by al13n used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef serpinski_glsl
#define serpinski_glsl

// This is a serpinski tetrahedron where
// the leaves are spheres (for efficiency). They can
// be made into tetrahedrons using sdTetrahedron.
float sdf(vec3 p)
{
    p *= 2.5;
    const vec3 p0 = vec3(-1, -1, -1);
    const vec3 p1 = vec3(1, 1, -1);
    const vec3 p2 = vec3(1, -1, 1);
    const vec3 p3 = vec3(-1, 1, 1);

    const int maxit = 25;
    // Scale factor for each iteration
    const float scale = 2.0;
    const float minSize = pow(scale, -float(maxit - 2));

    for (int i = 0; i < maxit; ++i) {
        float d = distance(p, p0);
        vec3 c = p0;

        float t = distance(p, p1);
        if (t < d) {
            d = t;
            c = p1;
        }

        t = distance(p, p2);
        if (t < d) {
            d = t;
            c = p2;
        }

        t = distance(p, p3);
        if (t < d) {
            d = t;
            c = p3;
        }

        p = (p - c) * scale;
    }

    return (1.0/2.5) * (length(p) * pow(scale, float(-maxit)) - minSize);
}


#endif
