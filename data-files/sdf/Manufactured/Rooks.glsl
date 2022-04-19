/*
Copyright 2020 @eiffie
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wsBfzW
*/

/******************************************************************************
 This work is a derivative of work by eiffie used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef chess_glsl
#define chess_glsl

//adjust ENDFRAME, if it runs too fast make it higher
#define ENDFRAME 54.
#define rez iResolution
#define TAU 6.283
#define PAWN 1.0
#define ROOK 5.0
#define KNIGHT 4.0
#define BISHOP 3.0
#define QUEEN 9.0
#define KING 100.0
#define ILLEGAL -1000.0
//#define half 0.5
#define wid 8.0
#define zero 0.0
#define one 1.0
#define two 2.0
//#define get(v) texture(iChannel0,(vec2(floor((v).x),floor((v).y))+vec2(half))/iResolution.xy)
#define same(x,y) all(equal(floor(x),floor(y)))
#define fsame(x,y) (floor(x)==floor(y))
#define isZero(x) (abs(x)<half)
#define STATEVEC (rez.xy-vec2(one))
#define SCOREFRAME ENDFRAME-3.
#define BESTFRAME ENDFRAME-2.
#define ssgn(x) ((x)-.1>0.?1.:(x)+.1<0.?-1.:0.)

//random seed and generator
vec2 randv2;
vec2 rand2(){// implementation derived from one found at: lumina.sourceforge.net/Tutorials/Noise.html
 randv2+=vec2(1.0,1.0);
 return vec2(fract(sin(dot(randv2.xy ,vec2(12.9898,78.233))) * 4375.5453),
  fract(cos(dot(randv2.xy ,vec2(4.898,7.23))) * 2342.631));
}

//CHEBYSHEV rotations for KING and KNIGHT moves
#define cPi (two*two)
float cCos(float a){return clamp(abs(mod(a,two*cPi)-cPi)-cPi/two,-one,one);}
float cSin(float a){return cCos(a-cPi/two);}
vec2 rookMove(float j, vec2 p){return j<wid?vec2(j-p.x,zero):vec2(zero,j-wid-p.y);}
vec2 bishopMove(float j, vec2 p){return j<wid?vec2(j-p.x):vec2(j-wid-p.x,p.x-j+wid);}

vec4 setup1(vec2 p){//find starting positions
  vec4 v=vec4(zero,zero,zero,one);
  vec2 ap=floor(abs(p-vec2(4.)));
  p=floor(p);
  if(ap.y==3.){
    if(ap.x==3.)v.x=ROOK;
    else if(ap.x==two)v.x=KNIGHT;
    else if(ap.x==one)v.x=BISHOP;
    else if(p.x<4.)v.x=QUEEN;
    else v.x=KING;
  }else if(ap.y==two)v.x=PAWN;
  if(v.x>0.)v.x*=sign(p.y-4.);
  return v;
}

//now the graphics, trying to mimick a packet of photons
const float fov = 4.0,blurAmount = 0.0005;
const int RaySteps=100, maxBounces=8;
const vec3 ior=vec3(1.0,2.0,1.0/2.0);//water=1.33,glass=1.52,diamond=2.42

struct material {vec3 color;float refrRefl,difExp,spec,specExp;};
float board(vec2 v){//read buffer for piece at this position
  if(max(abs(v.x),abs(v.y))>4.0)return 0.;
  return 5.0;
  //return get(v+vec2(4.)).r;
}
vec4 mcol; 
float DE(vec3 p0){ 
  vec3 p=vec3(fract(p0.x)-0.5,p0.y,fract(p0.z)-0.5); 
  float id=board(p0.xz),tp=abs(id); 
  float mx=0.65-max(abs(p.x),abs(p.z)); 
  if(tp==0.)return mx;//don't step too far into the next square 
  float f0=0.46,f1=2.7,f2=0.0,f3=0.25,f4=0.66,f5=-1.,f6=2.;//base config 
  float da=1.0,ds=1.0;//bits to add and subtract to the dif type pieces 
  if(tp==PAWN || tp==ROOK || tp==KNIGHT){p.y+=0.14;f6*=1.5;}//smaller pieces 
  p*=f6; 
  float r=length(p.xz); 
  if(p.y>0.8){f5=1.;f0=0.;//swap base for head config 
    if(tp==PAWN || tp==BISHOP){ 
      f1=3.3;f2=1.1;f3=(tp<4.?.3:.22);f4=1.57; 
      if(tp<BISHOP)da=length(p-vec3(0.,1.56,0.))-0.08; 
      else ds=max(-p.y+1.0,abs(p.z-p.y*0.5+.5)-0.05); 
    }else if(tp==ROOK){
      f1=2.6;f2=8.;f3=.5;f4=1.3; 
      ds=max(-p.y+1.,min(r-.37,min(abs(p.x),abs(p.z))-0.09)); 
    }else if(tp>ROOK){//queen and king 
      f1=3.3;f2=0.81;f3=.28;f4=1.3; 
      if(tp<KING){ 
        da=length(vec3(abs(p.x)-.19,p.y-1.33,abs(p.z)-.19))-0.1; 
      }else{ 
        da=max(p.y-1.75,min(r-0.02,max(abs(p.x)-.2,length(p.yz-vec2(1.59,0.))-0.02))); 
      } 
    }else{//knight 
      f1=2.,f2=3.4,f3=.31,f4=1.5; 
      float az=abs(p.z)-(p.y-1.)*0.18; 
      da=max(az-.16-p.x*.25,max(abs(p.x+.2-az*.17)-.34,abs(p.y-p.x*.16-1.19-az*.24)-.29-p.x*.16*2.)); 
      ds=min(length(p.xy-vec2(-.53,1.09)),length(p.xy-vec2(0.,1.3)))-.07;
    } 
  }  
  float d=r-f0+sin(p.y*f1+f2)*f3; 
  d=max(d,p.y*f5-f4); 
  da=min(da,length(max(vec2(r-0.28,abs(p.y-0.8)),0.))-0.05); 
  d=max(min(d,da),-ds); 
  mcol=vec4(vec3(id<0.?0.2:1.),-sign(id)*0.005); 
  return min(0.83*d/f6,mx);
}
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( in vec3 p, in vec3 b )
{
    vec3 d = abs(p) - b;
    return min( max(max(d.x,d.y),d.z),0.0) + length(max(d,0.0));
}

float sdf(vec3 p) {
    float boxD = sdBox(p, vec3(1.,1.,1.));
    return max(boxD, DE(p)) * 0.5;

}

#endif
