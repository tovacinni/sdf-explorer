/*
Copyright 2014 @jedi_cy
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/lslGWf
*/

/******************************************************************************
 This work is a derivative of work by jedi_cy used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef piano_glsl
#define piano_glsl

const float hinge_angle = pi / 2.0;

vec3 place_pos = vec3(10.0,0.0,40.0);

#define EPSILON 0.2

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

struct Obj
{
    float m_dist;
    int m_obj_idx;//0:floor 1:wall 2:piano body 3:w keys 4:b keys  5: sound board 6:gold mat 7:string
};

void Choose(in Obj obj1, in Obj obj2, out Obj obj)
{
    if (obj1.m_dist> obj2.m_dist)
    {
        obj = obj2;
    }
    else
    {
        obj = obj1;
    }
}

//------------------------------------------------------
float Combine(float re1, float re2)
{
    if (re1<0.0 || re2 <0.0)
        return max(re1, re2);
    return sqrt(re1*re1 + re2*re2);
}

float Subtract(float re1, float sub)
{
    if (sub>0.0)
        return re1;
    return max(-sub, re1);
}

float MapBox(in vec3 pos, in vec3 half_size)
{//center at (0,0,0)
    vec3 v = abs(pos)-half_size;
    
    if (v.x<0.0 || v.y <0.0 || v.z<0.0)
        return max(max(v.x, v.y), v.z);
    return length(v);
}

float MapBoxSim(in vec3 pos, in vec3 half_size)//no inside info
{//center at (0,0,0)
    return length(max(abs(pos)-half_size,0.0))-0.1;
}

float MapRoundBox(in vec3 pos, in vec3 half_size, in float r)//no inside info
{
    return length(max(abs(pos)-half_size,0.0))-r;
}

float Map2Box(in vec3 pos, in vec2 top_half_size, in vec2 bottom_half_size, in float half_h)
{//center at (0,0,0)
    float y = abs(pos.y) - half_h;
    float p = pos.y*0.5/half_h + 0.5;
    p = clamp(p, 0.0,1.0);//bottom---top
    float x = abs(pos.x) - mix(bottom_half_size.x, top_half_size.x, p);
    float z = abs(pos.z) - mix(bottom_half_size.y, top_half_size.y, p);
    
    if (x<0.0 || y <0.0 || z<0.0)
        return max(max(x, y), z);
    return sqrt(x*x + y*y + z*z);
}

float MapCylinder(in vec3 pos, in float r, in float half_h)
{
    float y = abs(pos.y) - half_h;
    float rr = length(pos.xz) - r;
    return Combine(y, rr);
}
//-------------------------------------------------------------------------------------------
//unit 100 == 1 meter
void MapFloor(in vec3 world_pos, out Obj obj)
{
    float dist = 150.0-abs(world_pos.y - 150.0);
    if (dist <= EPSILON)
    {
        obj.m_obj_idx = 0;
    }
    
    obj.m_dist = dist;
}

void MapWall(in vec3 world_pos, out Obj obj)
{   
    float x_dist = 200.0 - abs(world_pos.x);
    float z_dist = 300.0 - abs(world_pos.z);
    float dist = min(x_dist, z_dist);
    if (dist <= EPSILON)
    {
        obj.m_obj_idx = 1;
    }
    obj.m_dist = dist;
}


float MapPianoBodyShapeDist(in float x, in float y)
{
    if (y > 118.0)
    {//semi circle
        return sqrt((x+30.0)*(x+30.0)+(y-118.0)*(y-118.0)) - 45.0;
    }
    if (y>42.0)
    {
        //box
        float vx = -x - 75.0;
        //sin shape
        float sinv = sin(((y - 42.0)/76.0 + 0.5) * pi);
        sinv = x - (sinv*30.0 + 45.0);
        
        if (x<-30.0)
        {
            return vx;
        }
        return max(sinv, vx);
    }
    float xx = abs(x) - 75.0;
    return Combine(xx, 42.0-y);
}

float MapCover0(in vec3 pos)
{
    float re = MapPianoBodyShapeDist(-pos.x, pos.z);
    float re_2 = abs(pos.y) - 1.0;
    return Combine(re, re_2);
}
float MapBody(in vec3 pos)
{
    float re = MapPianoBodyShapeDist(-pos.x, pos.z);
    float re_2 = abs(pos.y) - 15.0;
    return Combine(re, re_2);
}

void MapPianoBody(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos;
    
    //backfoot
    float re = Map2Box(pos - vec3(30.0, 40.0, 155.0), vec2(15.0,3.2), vec2(3.0,3.0), 35.0);
    
    //foot1
    float re_2 = Map2Box(pos - vec3(-67.0, 40.0, 12.0), vec2(5.0,12.5), vec2(3.0,3.0), 35.0);
    re = min(re, re_2);
    //foot2
    re_2 = Map2Box(pos - vec3(67.0, 40.0, 12.0), vec2(5.0,12.5), vec2(3.0,3.0), 35.0);
    re = min(re, re_2);
    
    //pedal box
    re_2 = MapBoxSim(pos - vec3(0.0, 10.0, 12.0), vec3(14.0,5.0,5.0));
    re = min(re, re_2);
    //pedal box2
    re_2 = Map2Box(pos - vec3(0.0, 42.5, 14.0), vec2(14.0,4.0), vec2(5.0,2.0), 35.0);
    re = min(re, re_2);
    
    //keyboard bottom
    re_2 = MapBoxSim(pos - vec3(0.0, 74.5, -9.0), vec3(75.0, 4.5, 9.0));
    re = min(re, re_2);
    
    //keyboard two side
    re_2 = MapBoxSim(pos - vec3(68.0, 77.0, -9.0), vec3(7.0, 7.0, 9.0));
    re = min(re, re_2);
    re_2 = MapBoxSim(pos - vec3(-70.0, 77.0, -9.0), vec3(5.0, 7.0, 9.0));
    re = min(re, re_2);
    
    {//open cover
        vec3 pos_trans = pos + vec3(-75, -99.0, 0.0);
        float angle = abs(fract((hinge_angle +0.05)*0.05)-0.5);
        float sinv = sin(angle);
        float cosv = cos(angle);
        pos_trans.xy = pos_trans.xy * mat2(cosv, -sinv, sinv, cosv);
        pos_trans.x += 75.0;
        re_2 = MapCover0(pos_trans);
        re = min(re, re_2);
        
        re_2 = MapBoxSim(pos_trans - vec3(0.0, 3.0, 63.0), vec3(75.0, 1.0, 21.0));
        re = min(re, re_2);
    }
    
    {
        vec3 pos_temp = pos - vec3(0.0,83.0,21.0);
        float x = abs(pos_temp.x) - 75.0;
        float y = abs(pos_temp.y) - 13.0;
        float z = abs(pos_temp.z) - 21.0;
        z = Combine(x,z);//use to cal color
        if (pos_temp.z>0.0 && pos_temp.z<22.0)
        {
            z = x;
        }
        z = abs(z + 4.0) - 4.0;
        re_2 = Combine(z, y);
        re = min(re, re_2);
        
        pos_temp = pos - vec3(0.0,83.0,0.0);
        y = MapPianoBodyShapeDist(-pos_temp.x, pos_temp.z);//use to cal color
        if (pos_temp.z >40.0 && pos_temp.z<44.0)
        {
            y = abs(pos_temp.x) - 75.0;
        }
        y = abs(y + 4.0) - 4.0;
        z = abs(pos_temp.y) - 13.0;
        re_2 = Combine(y, z);
        re = min(re, re_2);
    
        if (re <= EPSILON)
        {
            obj.m_obj_idx = 2;
        }
    }
    obj.m_dist = re;
}

void MapBodySoundboard(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos -  vec3(0.0,80.0,-10.0);
    float re_3 = MapPianoBodyShapeDist(-pos.x, pos.z);
    float re_2 = abs(pos.y) - 6.0;
    float re = Combine(re_3, re_2) + 4.0;
    
    if (re< EPSILON)
    {
        obj.m_obj_idx = 5;
    }
    obj.m_dist = re;
}

void MapGoldObjs(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos;
    
    //wheel
    float re = MapCylinder((pos-vec3(-67.0, 3.0, 12.0)).xzy, 2.5, 5.0);
    float re_2 = MapCylinder((pos-vec3(67.0, 3.0, 12.0)).zxy, 2.5, 5.0);
    re = min(re, re_2);
    re_2 = MapCylinder((pos-vec3(30.0, 3.0, 155.0)).xzy, 2.5, 5.0);
    re = min(re, re_2);
    
    //pedal
    re_2 = MapBoxSim(pos - vec3(0.0,7.0,3.0), vec3(2.0, 0.5, 5.0));
    re = min(re, re_2);
    re_2 = MapBoxSim(pos - vec3(9.0,7.0,3.0), vec3(2.0, 0.5, 5.0));
    re = min(re, re_2);
    re_2 = MapBoxSim(pos - vec3(-9.0,7.0,3.0), vec3(2.0, 0.5, 5.0));
    re = min(re, re_2);
    
    //inner box
    re_2 = MapBoxSim(pos - vec3(0.0, 80.0, 18.0), vec3(70.0, 10.0, 14.0));
    re = min(re, re_2);
    
    //inner
    {
        vec3 pos_1 = pos -  vec3(0.0,85.0,0.0);
        float re_3 = MapPianoBodyShapeDist(-pos_1.x, pos_1.z);
        float re_2 = abs(pos_1.y) - 14.0;
        re_2 = Combine(re_3, re_2) + 10.0;
        
        float sinv = sin(-0.66);
        float cosv = cos(-0.66);
        pos_1.x -= 40.0;
        pos_1.z -=30.0;
        pos_1.xz = pos_1.xz * mat2(cosv, -sinv, sinv, cosv);
        re_3 = MapBox(pos_1, vec3(110.0,25.0,60.0));
        re_2 = Subtract(re_2, re_3);
        re_2 += 3.0;
        
        //line
        re_3 = MapBoxSim(pos - vec3(-59.0, 85.0, 27.0), vec3(1.0, 10.0, 23.0));
        re_2 = min(re_2, re_3);
        re_3 = MapBoxSim(pos - vec3(-30.0, 85.0, 40.0), vec3(1.0, 10.0, 36.0));
        re_2 = min(re_2, re_3);
        re_3 = MapBoxSim(pos - vec3(-4.0, 85.0, 50.0), vec3(1.0, 10.0, 46.0));
        re_2 = min(re_2, re_3);
        re_3 = MapBoxSim(pos - vec3(26.0, 85.0, 70.0), vec3(1.0, 10.0, 66.0));
        re_2 = min(re_2, re_3);
        re_3 = MapBoxSim(pos - vec3(62.0, 85.0, 75.0), vec3(1.0, 10.0, 71.0));
        re_2 = min(re_2, re_3);
        
        //hole
        re_3 = MapCylinder(pos - vec3(-42.0, 85.0, 60.0), 4.0, 10.0);
        re_2 = Subtract(re_2, re_3);
        re_3 = MapCylinder(pos - vec3(-17.0, 85.0, 82.0), 5.0, 10.0);
        re_2 = Subtract(re_2, re_3);
        re_3 = MapCylinder(pos - vec3(9.0, 85.0, 115.0), 6.0, 10.0);
        re_2 = Subtract(re_2, re_3);
        
        re = min(re, re_2);
    }
    
    if (re< EPSILON)
    {
        obj.m_obj_idx = 6;
    }
    obj.m_dist = re;
}

void MapString(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos - vec3(0.0, 85.0,80.0);
    
    float re = MapBox(world_pos + place_pos - vec3(0.0, 85.0,80.0), vec3(56.5,0.001,54.0));
    
    float sinv = sin(-0.66);
    float cosv = cos(-0.66);
    pos.z -= 80.0;
    pos.xz = pos.xz * mat2(cosv, -sinv, sinv, cosv);
    float re_2 = MapBox(pos, vec3(130.0,25.0,60.0));
    re = Subtract(re, re_2);
    
    if (re< EPSILON)
    {
        re_2 = (world_pos.x + 56.5)/113.0*88.0;
        re_2 = abs(fract(re_2) - 0.5);
        if (re_2 < 0.499)
            re = max(re, re_2*2.5681818181818181818181818181818);
    }
    
    if (re< EPSILON)
    {
        obj.m_obj_idx = 7;
    }
    obj.m_dist = re;
}

void MapBlackKeys(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos - vec3(-2.0, 82.75, -5.0);
    float re = MapBoxSim(pos, vec3(63.0, 0.75, 5.0));
    
    if (re <= EPSILON)
    {
        float x = clamp(pos.x/126.0 + 0.5, 0.0, 1.0);//0--1
        if (x<0.03175)//high pitch clamp
        {
            re = max(re, (0.03175-x)*126.0);
        }
        else if (x> 0.984)//low pitch clamp
        {
            re = max(re, (1.0-x)*126.0);
        }
        else
        {
            x = clamp(x-0.02, 0.0,1.0);
            x = fract(x*7.4285714285714285714285714285714);//group num
            if (x<0.1)//#A -- B
                re = max(re, (0.1-x)*7.4285714285714285714285714285714);
            else if (x>0.8861)//C---#C
                re = max(re, (x -0.8861)*7.4285714285714285714285714285714);
            else if (x>0.16 && x < 0.2476)//#G -- #A
                re = max(re, (0.2038-abs(x-0.2038))*7.4285714285714285714285714285714);
            else if (x>0.3343 && x< 0.395)//#F --- #G
                re = max(re, (0.36465-abs(x-0.36465))*7.4285714285714285714285714285714);
            else if (x>0.4817 && x< 0.6408)//#D -- #F
                re = max(re, (0.56125-abs(x-0.56125))*7.4285714285714285714285714285714);
            else if (x>0.7452 && x< 0.8159)//#C-- #D
                re = max(re, (0.78055-abs(x-0.78055))*7.4285714285714285714285714285714);
        }
    }
    
    if (re <= EPSILON)
    {
        obj.m_obj_idx = 4;
    }
    obj.m_dist = re;
}

void MapWhiteKeys(in vec3 world_pos, out Obj obj)
{
    vec3 pos = world_pos + place_pos - vec3(-2.0, 80.5, -7.5);
    float re = MapBoxSim(pos, vec3(63.0, 1.5, 7.5));
    if (re <= EPSILON)
    {
        obj.m_obj_idx = 3;
    }
    obj.m_dist = re;
}

//negative means inside
void Map(in vec3 world_pos, out Obj obj)//all rendering
{
    Obj obj_2;
    obj_2.m_obj_idx = -1;
    
    MapPianoBody(world_pos, obj);
    MapWhiteKeys(world_pos, obj_2);
    Choose(obj, obj_2, obj);
    MapBlackKeys(world_pos, obj_2);
    Choose(obj, obj_2, obj);
    MapBodySoundboard(world_pos,obj_2);
    Choose(obj, obj_2, obj);
    MapString(world_pos,obj_2);
    Choose(obj, obj_2, obj);
    MapGoldObjs(world_pos, obj_2);
    Choose(obj, obj_2, obj);
}

float sdf(vec3 p){
    p += vec3(0.,0.61,-0.2);
    p *= RotMat(vec3(0.,1.0,0.), pi);
    Obj obj;
    obj.m_obj_idx = -1;
    obj.m_dist = 9999.9;
    const float scale = 0.008;
    p *= (1.0 / scale);
    //p.z -= 3.0;
    Map(p, obj);
    return obj.m_dist * scale;
}
#endif

