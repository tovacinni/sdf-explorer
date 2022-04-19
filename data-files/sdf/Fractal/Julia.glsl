/*
Copyright 2013 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/MsfGRr
Archive Link: https://web.archive.org/web/20191113091856/https://www.shadertoy.com/view/MsfGRr
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef julia_glsl
#define julia_glsl

//--------------------------------------------------------------------------------
// quaternion manipulation
//--------------------------------------------------------------------------------

vec4 qSquare( vec4 a )
{
    return vec4( a.x*a.x - dot(a.yzw,a.yzw), 2.0*a.x*(a.yzw) );
}

vec4 qCube( vec4 a )
{
	return a * ( 4.0*a.x*a.x - dot(a,a)*vec4(3.0,1.0,1.0,1.0) );
}

vec3 julia_map( vec3 p, vec4 c )
{
    vec4 z = vec4( p, 0.2 );
	
	float m2 = 0.0;
	vec2  t = vec2( 1e10 );

	float dz2 = 1.0;
	for( int i=0; i<10; i++ ) 
	{
        // |dz|² = |3z²|²
		dz2 *= 9.0*lengthSquared(qSquare(z));
        
		// z = z^3 + c		
		z = qCube( z ) + c;
		
        // stop under divergence		
        m2 = dot(z, z);		
        if( m2>10000.0 ) break;				 

        // orbit trapping ( |z|² and z_x  )
		t = min( t, vec2( m2, abs(z.x)) );

	}

	// distance estimator: d(z) = 0.5·log|z|·|z|/|dz|   (see http://iquilezles.org/www/articles/distancefractals/distancefractals.htm)
	float d = 0.25 * log(m2) * sqrt(m2/dz2 );

	return vec3( d, t );
}

float sdf(vec3 p)
{
	const float t = 10.;
    const vec4 c = vec4(-0.1,0.6,0.9,-0.3) + 0.1*sin( vec4(3.0,0.0,1.0,2.0) + 0.5*vec4(1.0,1.3,1.7,2.1)*t);
	const float scale = 0.8;
	p *= 1. / scale;
	return julia_map(p, c).x * scale;
}

#endif
