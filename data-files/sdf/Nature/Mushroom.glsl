/*
Copyright 2017 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0
Link: https://www.shadertoy.com/view/4tByz3
Archive Link: https://web.archive.org/web/20191106030528/https://www.shadertoy.com/view/4tByz3
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef mushshroom_glsl
#define mushshroom_glsl

#define MAT_MUSH_HEAD 1.0
#define MAT_MUSH_NECK 2.0
#define MAT_LADY_BODY 3.0
#define MAT_LADY_HEAD 4.0
#define MAT_LADY_LEGS 5.0
#define MAT_GRASS     6.0
#define MAT_SHROOMGROUND    7.0
#define MAT_MOSS      8.0
#define MAT_CITA      9.0

#define TIME g3d_SceneTime

vec2 hash2( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*18.5453); }
vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(338.5453123,278.1459123,191.1234)); }
float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}
float length2(in vec3 p ) { return dot(p,p); }

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k) {
    return smin(a, b, -k);
}

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

float sdEllipsoid( in vec3 pos, in vec3 cen, in vec3 rad )
{
#if 1
    vec3 p = pos - cen;
    float d = length(p/rad) - 1.0;   
    return d * min(min(rad.x,rad.y),rad.z);
#else
    vec3 p = pos - cen;
    float k0 = length(p/rad);
    float k1 = length(p/(rad*rad));
    return k0*(k0-1.0)/k1;
#endif    
}
    
vec2 sdLine( in vec3 pos, in vec3 a, in vec3 b )
{
    vec3 pa = pos - a;
    vec3 ba = b - a;
   
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    
    return vec2( length(pa-h*ba), h );
}

vec2 sdLineOri( in vec3 p, in vec3 b )
{
    float h = clamp( dot(p,b)/dot(b,b), 0.0, 1.0 );
    
    return vec2( length(p-h*b), h );
}
vec2 sdLineOriY( in vec3 p, in float b )
{
    float h = clamp( p.y/b, 0.0, 1.0 );
    
    return vec2( length(vec3(p.x,p.y-b*h,p.z)), h );
}

//float length2(in vec3 p ) { return dot(p,p); }

vec3 rotateY( in vec3 p, float t )
{
    float co = cos(t);
    float si = sin(t);
    p.xz = mat2(co,-si,si,co)*p.xz;
    return p;
}

vec3 rotateX( in vec3 p, float t )
{
    float co = cos(t);
    float si = sin(t);
    p.yz = mat2(co,-si,si,co)*p.yz;
    return p;
}
vec3 rotateZ( in vec3 p, float t )
{
    float co = cos(t);
    float si = sin(t);
    p.xy = mat2(co,-si,si,co)*p.xy;
    return p;
}


//==================================================

#define ZERO 0

//==================================================

vec3 mapLadyBug( vec3 p, float curmin )
{
    
    float db = length(p-vec3(0.0,-0.35,0.05))-1.3;
    if( db>curmin ) return vec3(10000.0,0.0,0.0);
    
    float dBody = sdEllipsoid( p, vec3(0.0), vec3(0.8, 0.75, 1.0) );
    dBody = smax( dBody, -sdEllipsoid( p, vec3(0.0,-0.1,0.0), vec3(0.75, 0.7, 0.95) ), 0.05 );
    dBody = smax( dBody, -sdEllipsoid( p, vec3(0.0,0.0,0.8), vec3(0.35, 0.35, 0.5) ), 0.05 );
    dBody = smax( dBody, sdEllipsoid( p, vec3(0.0,1.7,-0.1), vec3(2.0, 2.0, 2.0) ), 0.05 );
    dBody = smax( dBody, -abs(p.x)+0.005, 0.02 + 0.1*clamp(p.z*p.z*p.z*p.z,0.0,1.0) );

    vec3 res = vec3( dBody, MAT_LADY_BODY, 0.0 );

    // --------
    vec3 hc = vec3(0.0,0.1,0.8);
    vec3 ph = rotateX(p-hc,0.5);
    float dHead = sdEllipsoid( ph, vec3(0.0,0.0,0.0), vec3(0.35, 0.25, 0.3) );
    dHead = smax( dHead, -sdEllipsoid( ph, vec3(0.0,-0.95,0.0), vec3(1.0) ), 0.03 );
    dHead = min( dHead, sdEllipsoid( ph, vec3(0.0,0.1,0.3), vec3(0.15,0.08,0.15) ) );

    if( dHead < res.x ) res = vec3( dHead, MAT_LADY_HEAD, 0.0 );
    
    res.x += 0.0007*sin(150.0*p.x)*sin(150.0*p.z)*sin(150.0*p.y); // iqiq

    // -------------
    
    vec3 k1 = vec3(0.42,-0.05,0.92);
    vec3 k2 = vec3(0.49,-0.2,1.05);
    float dLegs = 10.0;

    float sx = sign(p.x);
    p.x = abs(p.x);
    for( int k=0; k<3; k++ )
    {   
        vec3 q = p;
        q.y -= min(sx,0.0)*0.1;
        if( k==0) q += vec3( 0.0,0.11,0.0);
        if( k==1) q += vec3(-0.3,0.1,0.2);
        if( k==2) q += vec3(-0.3,0.1,0.6);
        
        vec2 se = sdLine( q, vec3(0.3,0.1,0.8), k1 );
        se.x -= 0.015 + 0.15*se.y*se.y*(1.0-se.y);
        dLegs = min(dLegs,se.x);

        se = sdLine( q, k1, k2 );
        se.x -= 0.01 + 0.01*se.y;
        dLegs = min(dLegs,se.x);

        se = sdLine( q, k2, k2 + vec3(0.1,0.0,0.1) );
        se.x -= 0.02 - 0.01*se.y;
        dLegs = min(dLegs,se.x);
    }
    
    if( dLegs<res.x ) res = vec3(dLegs,MAT_LADY_LEGS, 0.0);


    return res;
}


vec3 worldToMushrom( in vec3 pos )
{
    vec3 qos = pos;
    qos.xy = (mat2(60,11,-11,60)/61.0) * qos.xy;
    qos.y += 0.03*sin(3.0*qos.z - 2.0*sin(3.0*qos.x));
    qos.y -= 0.4;
    return qos;
}

vec3 mapMushroom( in vec3 pos, in vec3 cur )
{
    vec3 res = cur;

    vec3 qos = worldToMushrom(pos);
    float db = length(qos-vec3(0.0,1.2,0.0)) - 1.3;
    if( db<cur.x )
    {

        {

            float d1 = sdEllipsoid( qos, vec3(0.0, 1.4,0.0), vec3(0.8,1.0,0.8) );

            //d1 -= 0.025*textureLod( iChannel1, 0.05*qos.xz, 0.0 ).x - 0.02;

            float d2 = sdEllipsoid( qos, vec3(0.0, 0.5,0.0), vec3(1.3,1.2,1.3) );
            float d = smax( d1, -d2, 0.1 );
            d *= 0.8;
            if( d<res.x )
            {
                res = vec3( d, MAT_MUSH_HEAD, 0.0 );
            }
        }


        {
            pos.x += 0.3*sin(pos.y) - 0.65;
            float pa = sin( 20.0*atan(pos.z,pos.x) );
            vec2 se = sdLine( pos, vec3(0.0,2.0,0.0), vec3(0.0,0.0,0.0) );

            float tt = 0.25 - 0.1*4.0*se.y*(1.0-se.y);

            float d3 = se.x - tt;

            d3 = smin( d3, sdEllipsoid( pos, vec3(0.0, 1.7 - 2.0*length2(pos.xz),0.0), vec3(0.3,0.05,0.3) ), 0.05);
            d3 += 0.003*pa;
            d3 *= 0.7;
            
            if( d3<res.x )
                res = vec3( d3, MAT_MUSH_NECK, 0.0 ) * 0.7;
        }
    
    }
    return res;
}



vec3 mapGrass( in vec3 pos, float h, in vec3 cur )
{
    vec3 res = cur;
    
    float db = pos.y-2.6;
    
    if( db<cur.x && pos.z>-1.65 )
    {
        const float gf = 4.0;

        vec3 qos = pos * gf;

        vec2 n = floor( qos.xz );
        vec2 f = fract( qos.xz );
        for( int j=-2; j<=2; j++ )
        for( int i=-2; i<=2; i++ )
        {
            vec2  g = vec2( float(i), float(j) );

            vec2 ra2 = hash2( n + g + vec2(31.0,57.0) );

            if( ra2.x<0.73 ) continue;

            vec2  o = hash2( n + g );
            vec2  r = g - f + o;
            vec2 ra = hash2( n + g + vec2(11.0,37.0) );

            float gh = 2.0*(0.3+0.7*ra.x);

            float rosy = qos.y - h*gf;

            r.xy = reflect( r.xy, normalize(-1.0+2.0*ra) );
            r.x -= 0.03*rosy*rosy;

            r.x *= 4.0;

            float mo = 0.1*sin( 2.0*TIME + 20.0*ra.y )*(0.2+0.8*ra.x);
            vec2 se = sdLineOri( vec3(r.x,rosy,r.y), vec3(4.0 + mo,gh*gf,mo) );

            float gr = 0.3*sqrt(1.0-0.99*se.y);
            float d = se.x - gr;
            d /= 4.0;

            d /= gf;
            if( d<res.x )
            {
                res.x = d;
                res.y = MAT_GRASS;
                res.z = r.y;
            }
        }
    }
    
    return res;
}


vec3 mapCrapInTheAir( in vec3 pos, in vec3 cur)
{
    vec3 res = cur;
    
    ivec2 id = ivec2(floor((pos.xz+2.0)/4.0));
    pos.xz = mod(pos.xz+2.0,4.0)-2.0;
    float dm = 1e10;
    for( int i=ZERO; i<4; i++ )
    {
        vec3 o = vec3(0.0,3.2,0.0);
        o += vec3(1.7,1.50,1.7)*(-1.0 + 2.0*hash3(float(i)));
        o += vec3(0.3,0.15,0.3)*sin(0.3*TIME + vec3(float(i+id.y),float(i+3+id.x),float(i*2+1+2*id.x)));
        float d = length2(pos - o);
        dm = min(d,dm);
    }
    dm = sqrt(dm)-0.02;
    
    if( dm<res.x )
        res = vec3( dm,MAT_CITA,0);
    
    return res;
}

vec3 mapMoss( in vec3 pos, float h, vec3 cur)
{
    vec3 res = cur;

    float db = pos.y-2.2;
    if( db<res.x )
    {
    const float gf = 2.0;
    
    vec3 qos = pos * gf;
    vec2 n = floor( qos.xz );
    vec2 f = fract( qos.xz );

    for( int k=ZERO; k<2; k++ )
    {
        for( int j=-1; j<=1; j++ )
        for( int i=-1; i<=1; i++ )
        {
            vec2  g = vec2( float(i), float(j) );
            vec2  o = hash2( n + g + vec2(float(k),float(k*5)));
            vec2  r = g - f + o;

            vec2 ra  = hash2( n + g + vec2(11.0, 37.0) + float(2*k) );
            vec2 ra2 = hash2( n + g + vec2(41.0,137.0) + float(3*k) );

            float mh = 0.5 + 1.0*ra2.y;
            vec3 ros = qos - vec3(0.0,h*gf,0.0);

            vec3 rr = vec3(r.x,ros.y,r.y);

            rr.xz = reflect( rr.xz, normalize(-1.0+2.0*ra) );

            rr.xz += 0.5*(-1.0+2.0*ra2);
            vec2 se  = sdLineOriY( rr, gf*mh );
            float sey = se.y;
            float d = se.x - 0.05*(2.0-smoothstep(0.0,0.1,abs(se.y-0.9)));

            vec3 pp = vec3(rr.x,mod(rr.y+0.2*0.0,0.4)-0.2*0.0,rr.z);

            float an = mod( 21.0*floor( (rr.y+0.2*0.0)/0.4 ), 1.57 );
            float cc = cos(an);
            float ss = sin(an);
            pp.xz = mat2(cc,ss,-ss,cc)*pp.xz;

            pp.xz = abs(pp.xz);
            vec3 ppp = (pp.z>pp.x) ? pp.zyx : pp; 
            vec2 se2 = sdLineOri( ppp, vec3( 0.4,0.3,0.0) );
            vec2 se3 = sdLineOri( pp,  vec3( 0.2,0.3,0.2) ); if( se3.x<se2.x ) se2 = se3;
            float d2 = se2.x - (0.02 + 0.03*se2.y);

            d2 = max( d2, (rr.y-0.83*gf*mh) );
            d = smin( d, d2, 0.05 );

            d /= gf;
            d *= 0.9;
            if( d<res.x )
            {
                res.x = d;
                res.y = MAT_MOSS;
                res.z = clamp(length(rr.xz)*4.0+rr.y*0.2,0.0,1.0);
                float e = clamp((pos.y - h)/1.0,0.0,1.0);
                res.z *= 0.02 + 0.98*e*e;
                
                if( ra.y>0.85 && abs(se.y-0.95)<0.1 ) res.z = -res.z;
            }
        }
    }

    }
    
    return res;
}


vec3 worldToLadyBug( in vec3 p )
{
    // TODO: combine all of the above in a single 4x4 matrix
    p = 4.0*(p - vec3(-0.0,3.2-0.6,-0.57));
    p = rotateY( rotateZ( rotateX( p, -0.92 ), 0.49), 3.5 );
    p.y += 0.2;
    return p;
}


const vec3 mushroomPos1 = vec3( 0.0,0.1,0.0);
const vec3 mushroomPos2 = vec3(-3.0,0.0,3.0);

float terrain( in vec2 pos )
{
    return 0.3 - 0.3*sin(pos.x*0.5 - sin(pos.y*0.5));
}

vec3 mapShadow( in vec3 pos )
{
    float h = terrain( pos.xz );
    //float d = pos.y - h;
    //float d = pos.y;
    //vec3 res = vec3( d, MAT_SHROOMGROUND, 0.0 );
    vec3 res = vec3(10.,0.,0.);

    //res = mapGrass(pos,h,res);
    //res = mapMoss(pos,h,res);

    vec3 m1 =  pos - mushroomPos1;
    //vec3 m2 = (pos - mushroomPos2).zyx;
    //if( length2(m2.xz) < length2(m1.xz) ) m1 = m2;
    res = mapMushroom(m1, res);


    vec3 q = worldToLadyBug(pos);
    vec3 d3 = mapLadyBug(q, res.x*4.0); d3.x/=4.0;
    if( d3.x<res.x ) res = d3;

    return res;
}


vec3 mapShroom( in vec3 pos )
{
    vec3 res = mapShadow(pos);
        
    //res = mapCrapInTheAir(pos, res);

    return res;
}

float sdf(vec3 p)
{
    p -= vec3(0.2,-0.7,0.);
    p *= RotMat(vec3(0.,1.,0.), pi);
    const float scale = 0.55;
    p *= 1. / scale;
    return mapShroom(p).x * scale;
}

#endif
