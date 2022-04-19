PATH_TO_G3D=${1:-"/home/$USER/code/g3d"}

export g3d=$PATH_TO_G3D
export G3D10DATA=$g3d/G3D10/data-files:$g3d/data10/common:$g3d/data10/game:$g3d/data10/research
export INCLUDE=$g3d/G3D10/external/glew.lib/include:$g3d/G3D10/external/glfw.lib/include:$g3d/G3D10/external/civetweb.lib/include:$g3d/G3D10/external/qrencode.lib/include:$g3d/G3D10/external/zlib.lib/include:$g3d/G3D10/external/physx/include:$g3d/G3D10/G3D-base.lib/include:$g3d/G3D10/G3D-gfx.lib/include:$g3d/G3D10/G3D-app.lib/include:$g3d/G3D10/external/tbb/include:$g3d/G3D10/external/glslang/glslang:$INCLUDE
export LIBRARY=$g3d/G3D10/build/lib:$g3d/G3D10/build/bin:$LIBRARY
export PATH=$PATH:$g3d/G3D10/build/bin
export LD_LIBRARY_PATH=$g3d/G3D10/build/bin:$LD_LIBRARY_PATH
