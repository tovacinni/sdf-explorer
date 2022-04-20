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

#include "App.h"

// Set to 1 to compile for headless Linux clusters or remote development
#define USE_EGL 0

G3D_START_AT_MAIN();

int main(int argc, const char* argv[]) {
#   if USE_EGL
        G3DSpecification spec;
        spec.defaultGuiPixelScale = 1.0f;
        initGLG3D(spec);
#   endif

    GApp::Settings settings(argc, argv);

    settings.window.caption             = "SDF Explorer";
    settings.window.width               = 1280; settings.window.height       = 720;

    settings.window.fullScreen          = false;
    settings.window.resizable           = ! settings.window.fullScreen;
    settings.window.framed              = ! settings.window.fullScreen;
    settings.window.defaultIconFilename = "gui/icon.png";
    settings.window.asynchronous        = true;
    settings.hdrFramebuffer.depthGuardBandThickness    = Vector2int16(0, 0);
    settings.hdrFramebuffer.colorGuardBandThickness    = Vector2int16(0, 0);
    settings.dataDir                    = FileSystem::currentDirectory();

    if (settings.argArray.contains("--help")) {
        printf("SDF Explorer\n\n");

        printf("sdf-explorer [--help] [--sample <N> <Pattern> <SDF> <outfile>]\n\n");
        printf("If launched without arguments or from an icon, presents the\n");
        printf("graphical user interface. If run with the --sample argument,\n");
        printf("takes many samples from a SDF and saves them to disk without\n");
        printf("creating a visible operating system window. The sample\n");
        printf("parameters are:\n\n");

        printf("N             Positive integer number of samples to compute\n\n");

        printf("Pattern       Sampling pattern, which is the basename of a\n");
        printf("              GLSL file in the sampler directory. The built-in\n");
        printf("              sampling patterns are:\n\n");

        printf("              grid, image, jitter, near, rand, trace,\n");
        printf("              metropolis, metropolis_curvature\n\n");

        printf("SDF           Shape to sample. This is the basename of a GLSL\n");
        printf("              file in the sdf directory hierarchy, without the\n");
        printf("              path name or .glsl extension. See a directory\n");
        printf("              for the current options.\n\n");

        printf("outfile       Filename relative to the current directory to save\n");
        printf("              the binary result file in. The file uses platform\n");
        printf("              endianness and has the following format:\n\n");

        printf("              Value                Count       Format\n");
        printf("              ---------------------------------------\n");
        printf("              N                    1           uint32\n");
        printf("              Position X,Y,Z       N           float32 x 3\n");
        printf("              SDF(X,Y,Z)           N           float32\n");
        printf("              gradient             N           float32 x 3\n\n");
        return 0;
    }

    if (settings.argArray.contains("--sample")) {
        settings.window.visible = false;
    }
    OSWindow* window = nullptr;
    if (settings.argArray.contains("--headless")) {
#       if USE_EGL
#           ifndef G3D_LINUX
#               error "USE_EGL is only supported on Linux"
#           else
                window = EGLWindow::create(settings.window);
#           endif
#       else
            alwaysAssertM(false, "--headless requires compiling with #define USE_EGL 1");
#       endif
    }
    return App(settings, window).run();
}

App::App(const VRApp::Settings& settings, OSWindow* window) : super(settings, window) {}

void App::onInit() {
    super::onInit();

    // Search for sampler files
    FileSystem::getFiles("sampler/*.glsl", m_samplerArray);
    m_samplerArray.sort();

    // Search for shader files
    Array<String> shaderDirArray;
    FileSystem::getDirectories("sdf/*", shaderDirArray, true);
    for (const String &s : shaderDirArray) {
        Array<String> shaderArray;
        FileSystem::getFiles(FilePath::concat(s, "*.glsl"), shaderArray, true);
        m_shaderArray.append(shaderArray);
    }

    m_shaderArray.sort();
    m_activeShader = 0;
    int i = 0;
    for (const String& s : m_shaderArray) {
        m_shaderMins.push_back(5.0);
        const Array<String>& shaderSourceBuffer = stringSplit(readWholeFile(s).substr(0, 200), '\n');
        
        const String& license = format("%s SDF %s\n%s\n\n%s\n%s\n",
                FilePath::base(s).c_str(),
                shaderSourceBuffer[1].c_str(),
                shaderSourceBuffer[2].c_str(),
                "SDF Explorer Copyright 2020 NVIDIA Corporation",
                "By Towaki Takikawa and Morgan McGuire");
        m_shaderLicenseArray.push_back(license);

        if (s == "sdf/Geometry/Icosahedron.glsl") {
            // Default SDF
            m_activeShader = i;
        }
        ++i;
    }
    
    // Search for matcap files
    Array<String> matcapDirArray;
    FileSystem::getDirectories("matcap/*", matcapDirArray, true);
    for (const String &s : matcapDirArray) {
        Array<String> matcapArray;
        FileSystem::getFiles(FilePath::concat(s, "*"), matcapArray, true);
        m_matcapArray.append(matcapArray);
    }
    
    m_matcapArray.sort();
    for (const String &s : m_matcapArray) {
        m_matcapTextureArray.push_back(Texture::fromFile(s));
    }

    // Search for base color texture files
    Array<String> textureDirArray;
    FileSystem::getDirectories("texture/*", textureDirArray, true);
    
    for (const String &s : textureDirArray) {
        Array<String> colorArray;
        FileSystem::getFiles(FilePath::concat(s, "*_Color.*"), colorArray, true);
        m_colorArray.append(colorArray);
        
        Array<String> displacementArray;
        FileSystem::getFiles(FilePath::concat(s, "*_Displacement.*"), displacementArray, true);
        m_displacementArray.append(displacementArray);
        
        Array<String> normalArray;
        FileSystem::getFiles(FilePath::concat(s, "*_Normal.*"), normalArray, true);
        m_normalArray.append(normalArray);
    }
    
    m_colorArray.sort();
    m_displacementArray.sort();
    m_normalArray.sort();
    m_roughnessArray.sort();

    for (const String &s : m_colorArray) {
        m_colorTextureArray.push_back(Texture::fromFile(s));
    }
    for (const String &s : m_displacementArray) {
        m_displacementTextureArray.push_back(Texture::fromFile(s));
    }
    for (const String &s : m_normalArray) {
        m_normalTextureArray.push_back(Texture::fromFile(s));
    }
    for (const String &s : m_roughnessArray) {
        m_roughnessTextureArray.push_back(Texture::fromFile(s));
    }

    // Initialize control variables
    m_activeSampler = 0;
    m_activeMatcap = 0;
    m_activeColor = 0;
    m_activeDisplacement = 0;
    m_activeNormal = 0;
    m_sample = false;
    m_whiteBg = true; // TODO: Fix name
    m_coloredPlane = true; 
    m_boxPreview = false;
    m_cutPlane = false;
    m_groundPlane = true;
    m_solidCut = false;
    m_matcap = false;
    m_showLicense = true;
    m_adjustView = false;
    m_font = GFont::fromFile(System::findDataFile("arial.fnt"));
    m_copyrightFont = GFont::fromFile(System::findDataFile("arialblack.fnt"));
    m_sampleBase = "../samples";
    m_sampleSize = 1024*1024;
    m_sampleDim = 1024;

    // Degrees
    m_modelYaw = -20.0f;
    m_modelPitch = 0.0f;
    m_modelRoll = 0.0f;
    m_cutPlaneYaw = 0.0f;
    m_cutPlanePitch = 0.0f;
    m_cutPlaneOffset = 0.0f;
    m_modelRadius = 0.0f;
    m_groundPlaneHeight = -0.7f;
    m_cliSampleMode = false;

    setFrameDuration(1.0f / 240.0f);
    showRenderingStats  = false;
    developerWindow->sceneEditorWindow->setVisible(false);
    developerWindow->setVisible(false);
    developerWindow->cameraControlWindow->setVisible(false);
    developerWindow->cameraControlWindow->moveTo(Point2(developerWindow->cameraControlWindow->rect().x0(), 0));
    developerWindow->videoRecordDialog->setCaptureGui(false);

    loadScene("SDF Explorer");
    m_debugController->setMoveRate(1.0f);

    makeGUI();

    setActiveCamera(m_debugCamera);

    // Setup CLI sampling    
    // Uses basename as argument, not full GLSL path
    // Example: icompile --run --sample Sphere
    if (settings().argArray.contains("--sample")) {
        if (settings().argArray.end() - settings().argArray.find("--sample") != 5) {
            debugPrintf("Invalid arguments\n");
            printf("Format: sdf-explorer [--help] [--sample <N> <Pattern> <SDF> <outfile>]\n\n");
            setExitCode(1);
        } else {
            const String& sampleSizeStr = settings().argArray[settings().argArray.findIndex("--sample")+1];
            try {
                m_sampleSize = std::stoi(sampleSizeStr.c_str());
                debugPrintf("N: %d\n", m_sampleSize);
                m_sampleDim = (int) ceil(sqrt((float) m_sampleSize));
                debugPrintf("D: %d\n", m_sampleDim);
            } catch (...) {
                debugPrintf("Invalid arguments, make sure N is an valid integer\n");   
                setExitCode(1);
            }
            const String& sampleSampler = settings().argArray[settings().argArray.findIndex("--sample")+2];
            const String& sampleShader = settings().argArray[settings().argArray.findIndex("--sample")+3];
            m_sampleBase = settings().argArray[settings().argArray.findIndex("--sample")+4];
            debugPrintf("Pattern: %s\n", sampleSampler.c_str());
            debugPrintf("SDF: %s\n", sampleShader.c_str());
            
            bool found = false;
            for (int i = 0; i < m_shaderArray.size(); ++i) {
                if (FilePath::base(m_shaderArray[i]) == sampleShader) {
                    m_activeShader = i;
                    found = true;
                    m_cliSampleMode = true;
                    break;
                }
            }
            
            if (! found) {  
                debugPrintf("Not a valid SDF\n");
                setExitCode(1);
            }

            found = false;

            for (int i = 0; i < m_samplerArray.size(); ++i) {
                if (FilePath::base(m_samplerArray[i]) == sampleSampler) {
                    m_activeSampler = i;
                    found = true;
                    break;
                }
            }

            if (! found) {  
                debugPrintf("Not a valid sampler\n");
                setExitCode(1);
            }

        }
    }

    debugAssertM(m_shaderArray.size() > 0, "No shaders found");
    debugAssert(m_activeShader < m_shaderArray.size());
}


static String parentBase(const String& path) {
    const Array<String>& pathComponents = stringSplit(path, '/');
    return FilePath::concat(pathComponents[pathComponents.lastIndex()-1],
                            FilePath::base(pathComponents[pathComponents.lastIndex()]));
}


void App::makeGUI() {   
    Array<GuiText> shaderGuiArray;
    for (const String& sdfPath : m_shaderArray) {
        shaderGuiArray.push_back(replace(parentBase(sdfPath), "/", " "));
    }

    Array<GuiText> matcapGuiArray;
    matcapGuiArray.push_back("Analytic");
    matcapGuiArray.push_back("Surface Normals");
    matcapGuiArray.push_back("Mean Curvature");
    matcapGuiArray.push_back("Ambient Occlusion");
    for (const String& matcapPath : m_matcapArray) {
        matcapGuiArray.push_back(replace(parentBase(matcapPath), "/", " "));
    }
    
    Array<GuiText> samplerGuiArray;
    for (const String& samplerFile : m_samplerArray) {
        samplerGuiArray.push_back(FilePath::base(samplerFile));
    }

    Array<GuiText> colorGuiArray;
    colorGuiArray.push_back("None");
    for (const String& f : m_colorArray) {
        colorGuiArray.push_back(FilePath::base(f));
    }

    Array<GuiText> displacementGuiArray;
    displacementGuiArray.push_back("None");
    for (const String& f : m_displacementArray) {
        displacementGuiArray.push_back(FilePath::base(f));
    }

    Array<GuiText> normalGuiArray;
    normalGuiArray.push_back("None");
    for (const String& f : m_normalArray) {
        normalGuiArray.push_back(FilePath::base(f));
    }

    Array<GuiText> roughnessGuiArray;
    roughnessGuiArray.push_back("None");
    for (const String& f : m_roughnessArray) {
        roughnessGuiArray.push_back(FilePath::base(f));
    }


    shared_ptr<GuiWindow> 
    window = GuiWindow::create("Controls", debugWindow->theme(), 
                                 Rect2D::xywh(0,50,0,0), GuiTheme::TOOL_WINDOW_STYLE);
    GuiPane* pane = window->pane();
    
    const float tabSize = 32.0f;

    GuiDropDownList* shaderDropDown = pane->addDropDownList("Model", shaderGuiArray, &m_activeShader, [&](void) { m_adjustView = true; }, true);
    shaderDropDown->setSelectedValue(shaderGuiArray[m_activeShader]);

    GuiSlider<float>* modelYawSlider = pane->addSlider("Yaw", &m_modelYaw, -180.0f, 180.0f);
    modelYawSlider->moveBy(tabSize, 0.0f);
    modelYawSlider->setCaptionWidth(50.0f);
    modelYawSlider->setWidth(modelYawSlider->rect().width() - tabSize);
    
    GuiSlider<float>* modelPitchSlider = pane->addSlider("Pitch", &m_modelPitch, -180.0f, 180.0f);
    modelPitchSlider->moveBy(tabSize, 0.0f);
    modelPitchSlider->setCaptionWidth(50.0f);
    modelPitchSlider->setWidth(modelPitchSlider->rect().width() - tabSize);
    
    GuiSlider<float>* modelRollSlider = pane->addSlider("Roll", &m_modelRoll, -180.0f, 180.0f);
    modelRollSlider->moveBy(tabSize, 0.0f);
    modelRollSlider->setCaptionWidth(50.0f);
    modelRollSlider->setWidth(modelRollSlider->rect().width() - tabSize);
    
    GuiSlider<float>* modelRadiusSlider = pane->addSlider("Scale", &m_modelRadius, -1.0f, 1.0f);
    modelRadiusSlider->moveBy(tabSize, 0.0f);
    modelRadiusSlider->setCaptionWidth(50);
    modelRadiusSlider->setWidth(modelRadiusSlider->rect().width() - tabSize);
    
    pane->addDropDownList("Shading", matcapGuiArray, &m_activeMatcap, nullptr, true);
    pane->addDropDownList("Base Color", colorGuiArray, &m_activeColor, nullptr, true);
    pane->addDropDownList("Displacement", displacementGuiArray, &m_activeDisplacement, nullptr, true);
    pane->addDropDownList("Normal Map", normalGuiArray, &m_activeNormal, nullptr, true);
    pane->addCheckBox("Ground Plane", &m_groundPlane);
    GuiSlider<float>* elevationSlider = pane->addSlider("Height", &m_groundPlaneHeight, -1.0f, 1.0f);
    elevationSlider->moveBy(tabSize, 0.0f);
    elevationSlider->setCaptionWidth(50);
    elevationSlider->setWidth(elevationSlider->rect().width() - tabSize);
    pane->addCheckBox("Color", &m_coloredPlane)->moveBy(tabSize, 0);

    pane->addCheckBox("Background", &m_whiteBg);
    
    pane->addCheckBox("Visualization Plane", &m_cutPlane);
    GuiSlider<float>* cutPlaneYawSlider = pane->addSlider("Yaw", &m_cutPlaneYaw, -90.0f, 90.0f);
    cutPlaneYawSlider->moveBy(tabSize, 0.0f);
    cutPlaneYawSlider->setCaptionWidth(50);
    cutPlaneYawSlider->setWidth(cutPlaneYawSlider->rect().width() - tabSize);
    
    GuiSlider<float>* cutPlanePitchSlider = pane->addSlider("Pitch", &m_cutPlanePitch, -90.0f, 90.0f);
    cutPlanePitchSlider->moveBy(tabSize, 0.0f);
    cutPlanePitchSlider->setCaptionWidth(50);
    cutPlanePitchSlider->setWidth(cutPlanePitchSlider->rect().width() - tabSize);
    
    GuiSlider<float>* cutPlaneOffsetSlider = pane->addSlider("Offset", &m_cutPlaneOffset, -1.0f, 1.0f);
    cutPlaneOffsetSlider->moveBy(tabSize, 0.0f);
    cutPlaneOffsetSlider->setCaptionWidth(50.0f);
    cutPlaneOffsetSlider->setWidth(cutPlaneOffsetSlider->rect().width() - tabSize);
    pane->addCheckBox("Transparent", &m_solidCut)->moveBy(tabSize, 0);
    pane->addCheckBox("Show License", &m_showLicense);

    pane->addLabel("Debug");    
    GuiPane* debugPane = pane->addPane();
    GuiCheckBox* normCheckBox = debugPane->addCheckBox("Visualize [-1, 1]", &m_boxPreview);
    normCheckBox->setWidth(debugPane->rect().width() - 9);
    debugPane->addButton("Screenshot (F4)", [&](void) { screenCapture()->takeScreenshot(); } );

    /*
    pane->addLabel("Export Samples");
    GuiPane* samplerPane = pane->addPane();
    GuiDropDownList* samplerDropDown = samplerPane->addDropDownList("Sampler", samplerGuiArray, &m_activeSampler, nullptr);
    samplerDropDown->setCaptionWidth(60);
    samplerDropDown->setWidth(130);
    samplerPane->addButton("Sample", [&](void) { m_sample = true; } )->moveRightOf(samplerDropDown);
    */

    window->pack();
    window->setVisible(true);
    addWidget(window);
}


void App::allocateSSBO(shared_ptr<GLPixelTransferBuffer>& ssbo, int w, int h, int d, int bindpoint) {
    debugAssert(w >= 0 && h >= 0 && d >= 0);
    ssbo = GLPixelTransferBuffer::create(w, h, ImageFormat::RGBA32F(), nullptr, d, GL_DYNAMIC_DRAW);

    debugAssert(ssbo->glBufferID() != GL_NONE);
    ssbo->bindAsShaderStorageBuffer(bindpoint);
}


#ifdef G3D_LINUX
void App::findmin(RenderDevice* rd, float& minh) {
    if (isNull(m_findminSSBO)) {
        allocateSSBO(m_findminSSBO, 500, 500, 1, 10);
    }
    debugAssertGLOk();

    BEGIN_PROFILER_EVENT("SDF FindMin");
    
    const Rect2D viewport = Rect2D::xywh(0.0f, 0.0f, (float)m_findminSSBO->width(), (float)m_findminSSBO->height());
    {
        Args args;
        args.setRect(viewport);

        const float blockCols = 16.0f;
        const float blockRows = 16.0f;
        args.setMacro("ACTIVE_SHADER", m_shaderArray[m_activeShader]);
        args.setUniform("modelMatrix", CFrame::fromXYZYPRDegrees(0, 0, 0, 0, 0, 0));
        args.setUniform("modelRadius", m_modelRadius);
        args.setMacro("RENDER_DISPLACEMENT", false);
        // Must set this variable when launching a compute shader
        args.setComputeGridDim(Vector3int32(iCeil(viewport.width() / blockCols), 
                                            iCeil(viewport.height() / blockRows), 1 ));
        // In the current API, this variable is optional.
        args.setComputeGroupSize(Vector3int32((int)blockCols, (int)blockRows, 1));
        debugAssertGLOk();
        LAUNCH_SHADER("App/App_findmin.glc", args);
    }
    END_PROFILER_EVENT();
    float* dataPtr = (float*)m_findminSSBO->mapRead();
    
    runConcurrently(0, (int)(m_findminSSBO->size() / sizeof(float)), [&](int i) {
        minh = min(minh, dataPtr[i]);
    });

    m_findminSSBO->unmap();
    dataPtr = nullptr;
}
#endif


const shared_ptr<Texture>& uniformRandom3d() {
    static shared_ptr<Texture> t;

    Random rnd;
    srand((unsigned int)time(nullptr));
    rnd.reset(rand(), false);
    const shared_ptr<GLPixelTransferBuffer>& ptb = GLPixelTransferBuffer::create(1024, 1024, ImageFormat::RGB32F());
    {
        float* ptr = (float*)ptb->mapWrite();
        for (int i = 0; i < ptb->width() * ptb->height() * 3; ++i) {
            ptr[i] = float(rnd.uniform(0.0, 1.0)); ++i;
            ptr[i] = float(rnd.uniform(0.0, 1.0)); ++i;
            ptr[i] = float(rnd.uniform(0.0, 1.0));
        }
        ptr = nullptr;
        ptb->unmap();
    }
    t = Texture::fromPixelTransferBuffer("uniformRandom3d", ptb, ImageFormat::RGB32F(), Texture::DIM_2D, true);
    t->visualization.max = 1.0f;
    t->visualization.min = 0.0f;
    t->visualization.documentGamma = 2.1f;

    return t;
}


const shared_ptr<Texture>& gaussianRandom3d() {
    static shared_ptr<Texture> t;

    Random rnd;
    srand((unsigned int)time(nullptr));
    rnd.reset(rand(), false);
    const shared_ptr<GLPixelTransferBuffer>& ptb = GLPixelTransferBuffer::create(1024, 1024, ImageFormat::RGB32F());
    {
        float* ptr = (float*)ptb->mapWrite();
        for (int i = 0; i < ptb->width() * ptb->height() * 3; ++i) {
            ptr[i] = float(rnd.gaussian(0.0, 1.0)); ++i;
            ptr[i] = float(rnd.gaussian(0.0, 1.0)); ++i;
            ptr[i] = float(rnd.gaussian(0.0, 1.0));
        }
        ptr = nullptr;
        ptb->unmap();
    }
    t = Texture::fromPixelTransferBuffer("uniformGaussian3d", ptb, ImageFormat::RGB32F(), Texture::DIM_2D, true);
    t->visualization.max = 10.0f;
    t->visualization.min = -10.0f;
    t->visualization.documentGamma = 2.1f;

    return t;
}


void App::writeBinary(
    const String& name, 
    shared_ptr<GLPixelTransferBuffer> &ssbo_distance,
    shared_ptr<GLPixelTransferBuffer> &ssbo_normal) {

    const String& scheme = stringSplit(m_samplerArray[m_activeSampler], '.')[0];
    
    if (! FileSystem::exists(m_sampleBase)) {
        FileSystem::createDirectory(m_sampleBase);
    }
    
    const String& folderName = FilePath::concat(m_sampleBase, scheme);
    if (! FileSystem::exists(folderName)) {
        FileSystem::createDirectory(folderName);
    }
    
    const String& fname = FilePath::concat(folderName, FilePath::base(m_shaderArray[m_activeShader]) + ".bin");
    if (FileSystem::exists(fname)) {
        FileSystem::removeFile(fname);
    }
    
    BinaryOutput b(fname, G3D_LITTLE_ENDIAN);
    const Vector4* distPtr = (Vector4*)ssbo_distance->mapRead();
    //b.writeInt32((int) (ssbo_distance->size() / sizeof(float32)));
    b.writeInt32(m_sampleSize);
    //for (int i = 0; i < (int)(ssbo_distance->size() / sizeof(Vector4)); ++i) {
    for (int i = 0; i < m_sampleSize; ++i) {
        b.writeVector3(distPtr[i].xyz());
    }
    //for (int i = 0; i < (int)(ssbo_distance->size() / sizeof(Vector4)); ++i) {
    for (int i = 0; i < m_sampleSize; ++i) {
        b.writeFloat32(distPtr[i][3]);
    }
    ssbo_distance->unmap();
    const Vector4* normPtr = (Vector4*)ssbo_normal->mapRead();
    //for (int i = 0; i < (int)(ssbo_normal->size() / sizeof(Vector4)); ++i) {
    for (int i = 0; i < m_sampleSize; ++i) {
        b.writeVector3(normPtr[i].xyz());
    }
    ssbo_normal->unmap();
    b.commit();
    debugPrintf("Samples saved to: %s\n", fname.c_str());
    distPtr = nullptr;
    normPtr = nullptr;
}


#ifdef G3D_LINUX
void App::onSample(RenderDevice* rd) {
    const shared_ptr<Texture>& uniformSampler = uniformRandom3d(); 
    const shared_ptr<Texture>& gaussianSampler = gaussianRandom3d(); 
    //t->generateMipMaps();
    if (isNull(m_distanceSSBO)) {
        allocateSSBO(m_distanceSSBO, m_sampleDim, m_sampleDim, 1, 0);
    }

    if (isNull(m_normalSSBO)) {
        allocateSSBO(m_normalSSBO, m_sampleDim, m_sampleDim, 1, 1);
    }
 
    debugAssertGLOk();

    BEGIN_PROFILER_EVENT("SDF Sampling");
    const Rect2D viewport = Rect2D::xywh(0.0f, 0.0f, (float)m_distanceSSBO->width(), (float)m_distanceSSBO->height());
    {
        Args args;
        args.setRect(viewport);

        const float blockCols = 16.0f;
        const float blockRows = 16.0f;
        args.setUniform("uniformRandom3d", uniformSampler, Sampler(WrapMode::TILE, InterpolateMode::NEAREST_MIPMAP));
        args.setUniform("gaussianRandom3d", gaussianSampler, Sampler(WrapMode::TILE, InterpolateMode::NEAREST_MIPMAP));
        args.setMacro("ACTIVE_SHADER", m_shaderArray[m_activeShader]);
        args.setMacro("ACTIVE_SAMPLER", "sampler/" + m_samplerArray[m_activeSampler]); 
        args.setUniform("modelMatrix", CFrame::fromXYZYPRDegrees(0, 0, 0, 0, 0, 0));
        args.setUniform("modelRadius", m_modelRadius);
        args.setMacro("FAST", false);
        args.setComputeGridDim(Vector3int32(iCeil(viewport.width() / blockCols), iCeil(viewport.height() / blockRows), 1 ));
        args.setComputeGroupSize(Vector3int32((int)blockCols, (int)blockRows, 1));
        debugAssertGLOk();
        LAUNCH_SHADER("App/App_sample.glc", args);
    }
    END_PROFILER_EVENT();
    
    const String scheme = stringSplit(m_samplerArray[m_activeSampler], '.')[0];
    // Visualize in texture
    static shared_ptr<Texture> distanceTexture = Texture::createEmpty(
            "distance_" + scheme,
            m_distanceSSBO->width(), m_distanceSSBO->height(), m_distanceSSBO->format());
    distanceTexture->update(m_distanceSSBO);
    static shared_ptr<Texture> normalTexture = Texture::createEmpty(
            "normal_" + scheme,
            m_normalSSBO->width(), m_normalSSBO->height(), m_normalSSBO->format());
    normalTexture->update(m_normalSSBO);
    
    // Map data to CPU.
    writeBinary("distance", m_distanceSSBO, m_normalSSBO);
}
#endif 

void App::onGraphics3D(RenderDevice* rd, Array<shared_ptr<Surface> >& allSurfaces) {
    debugAssertM(m_activeShader < m_shaderArray.size(),
                 format("m_activeShader = %d, m_shaderArray.size() = %d",
                        m_activeShader, m_shaderArray.size()));
    
#ifdef G3D_LINUX
    // Raycast to find SDF y-direction min
    if (m_shaderMins[m_activeShader] > 3.0 || m_adjustView) {
        App::findmin(rd, m_shaderMins[m_activeShader]);
        CFrame frame = activeCamera()->frame();
        
        if (m_shaderMins[m_activeShader] > frame.translation.y) {
            frame.translation.y = m_shaderMins[m_activeShader] + 0.35f;
            frame.lookAt(Point3::zero());
            frame.translation += frame.leftVector() * 0.1;
            activeCamera()->setFrame(frame);
            m_debugCamera->setFrame(frame); 
            m_debugController->setFrame(frame);
        }
        m_adjustView = false;
    }

    if (m_cliSampleMode) {
        onSample(rd);
        debugPrintf("Sampling done, exiting\n");
        setExitCode(0);
    }

    // Sample points
    if (m_sample) {
        onSample(rd);
        m_sample = false;
    }
#endif 
    
    //debugPrintf("Tex Index %d\n", m_activeColor);

    // Render 3D
    BEGIN_PROFILER_EVENT("SDF Render");
    rd->push2D(m_framebuffer); {
        rd->setDepthWrite(true);
        Args args;
        activeCamera()->setShaderArgs(args, rd->viewport().wh(), "camera.");
        args.setRect(rd->viewport());
        args.setMacro("ACTIVE_SHADER", m_shaderArray[m_activeShader]);
        args.setMacro("RENDER_NORMBOX", m_boxPreview);
        args.setMacro("RENDER_CUTPLANE", m_cutPlane);
        args.setMacro("RENDER_GROUNDPLANE", m_groundPlane);
        args.setMacro("RENDER_WHITEBG", !m_whiteBg);
        args.setMacro("RENDER_PLANECOLOR", m_coloredPlane);
        args.setMacro("RENDER_SOLID", !m_solidCut);
        args.setMacro("FAST", false);
#ifdef G3D_LINUX
        args.setUniform("groundPlaneHeight", m_shaderMins[m_activeShader]);
#else 
        args.setUniform("groundPlaneHeight", m_groundPlaneHeight);
#endif 
        args.setMacro("RENDER_MATCAP", m_activeMatcap >= 4);
        args.setMacro("RENDER_COLOR", m_activeColor >= 1);
        args.setMacro("RENDER_DISPLACEMENT", m_activeDisplacement >= 1);
        args.setMacro("RENDER_NORMALMAP", m_activeNormal >= 1);
        args.setMacro("RENDER_NORMAL", m_activeMatcap == 1);
        args.setMacro("RENDER_CURVATURE", m_activeMatcap == 2);
        args.setMacro("RENDER_AO", m_activeMatcap == 3);
        args.setUniform("tmatcap", m_matcapTextureArray[max(m_activeMatcap-4, 0)], Sampler::cubeMap());
        args.setUniform("tcolor", m_colorTextureArray[max(m_activeColor-1, 0)], Sampler::cubeMap());
        args.setUniform("tdisplacement", m_displacementTextureArray[max(m_activeDisplacement-1, 0)], Sampler::cubeMap());
        args.setUniform("tnormal", m_normalTextureArray[max(m_activeNormal-1, 0)], Sampler::cubeMap());
        args.setUniform("modelMatrix", 
                        CFrame::fromXYZYPRDegrees(0, 0, 0, m_modelYaw, m_modelPitch, m_modelRoll));
        args.setUniform("cutPlaneMatrix", 
                        CFrame::fromXYZYPRDegrees(0, 0, m_cutPlaneOffset, m_cutPlaneYaw, m_cutPlanePitch, 0.));
        args.setUniform("modelRadius", m_modelRadius);
        LAUNCH_SHADER("App/App_visualize.pix", args);
    } rd->pop2D();
    END_PROFILER_EVENT();

    rd->pushState(m_framebuffer); {
        drawDebugShapes();
    } rd->pop2D();

    swapBuffers();
    rd->clear();

    // Post-processing
    m_film->exposeAndRender(rd, activeCamera()->filmSettings(), 
            m_framebuffer->texture(0), 
            settings().hdrFramebuffer.colorGuardBandThickness.x + 
            settings().hdrFramebuffer.depthGuardBandThickness.x, 
            settings().hdrFramebuffer.depthGuardBandThickness.x);
    
    // Labels 2D
    if (m_showLicense) {
        rd->push2D(); {
            const String& license = m_shaderLicenseArray[m_activeShader];
            const Array<String>& licenseLines = stringSplit(license, '\n');
            const float copyrightFontSize = min(min(rd->viewport().width(), rd->viewport().height()) * 0.1f, 12.0f);
            const int yOffset = int(-copyrightFontSize * 1.1 * licenseLines.size());
            for (int i = 0; i < licenseLines.size(); ++i) { 
                m_copyrightFont->draw2D(rd, licenseLines[i], 
                    rd->viewport().x0y1() + Vector2(20, yOffset + i * copyrightFontSize * 1.1f),
                    copyrightFontSize, 
                    Color3::white(), Color4(Color3::black(), 0.5f));
            }
        } rd->pop2D();
    }
}

