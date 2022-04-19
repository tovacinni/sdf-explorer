/******************************************************************************
 * The MIT License (MIT)
 * Copyright (c) 2021, NVIDIA CORPORATION.
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#pragma once

#include <G3D/G3D.h>
#include <map>

typedef GApp AppBase;

class App : public AppBase {
public:

    typedef AppBase super;
    
    App(const GApp::Settings& settings = GApp::Settings(), OSWindow* window = nullptr);

    virtual void onInit() override;
    virtual void onGraphics3D(RenderDevice* rd, Array<shared_ptr<Surface> >& surface3D) override;
    
    void makeGUI();
    void onSample(RenderDevice* rd);
    void onScreenshot(RenderDevice* rd);
    void findmin(RenderDevice* rd, float& minh);
    void allocateSSBO(shared_ptr<GLPixelTransferBuffer>& ssbo, int w, int h, int d, int bindpoint);
    void writeBinary(const String& name, shared_ptr<GLPixelTransferBuffer>& ssbo_distance,
                                         shared_ptr<GLPixelTransferBuffer>& ssbo_normal);
    bool m_boxPreview;
    bool m_cutPlane;
    bool m_groundPlane;
    float m_groundPlaneHeight;
    bool m_solidCut;
    bool m_whiteBg;
    bool m_coloredPlane;
    bool m_matcap;
    bool m_sample;
    bool m_cliSampleMode;
    bool m_showLicense;
    bool m_adjustView;

    int m_activeShader;
    
    int m_activeColor;
    int m_activeDisplacement;
    int m_activeNormal;
    int m_activeRoughness;
    
    int m_activeMatcap;
    int m_activeSampler;
    float m_cutPlaneYaw;
    float m_cutPlanePitch;
    float m_cutPlaneOffset;
    float m_modelYaw;
    float m_modelPitch;
    float m_modelRoll;
    float m_modelRadius;
    
    String m_sampleBase;
    int m_sampleSize;
    int m_sampleDim;

    Array<String> m_samplerArray;
    Array<String> m_shaderArray;
    Array<String> m_matcapArray;

    Array<String> m_colorArray;
    Array<String> m_displacementArray;
    Array<String> m_normalArray;
    Array<String> m_roughnessArray;
    
    Array<String> m_shaderLicenseArray;
    Array<float> m_shaderMins;

    Array<shared_ptr<Texture>> m_matcapTextureArray;
    
    Array<shared_ptr<Texture>> m_colorTextureArray;
    Array<shared_ptr<Texture>> m_displacementTextureArray;
    Array<shared_ptr<Texture>> m_normalTextureArray;
    Array<shared_ptr<Texture>> m_roughnessTextureArray;
    
    shared_ptr<GFont> m_font;
    shared_ptr<ThirdPersonManipulator> manipulator;
    shared_ptr<GuiWindow> m_window;

    shared_ptr<GLPixelTransferBuffer> m_distanceSSBO;
    shared_ptr<GLPixelTransferBuffer> m_normalSSBO;
    shared_ptr<GLPixelTransferBuffer> m_findminSSBO;
    shared_ptr<GFont>                 m_copyrightFont;
};

