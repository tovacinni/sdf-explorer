# The MIT License (MIT)
# Copyright (c) 2021, NVIDIA CORPORATION.
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import os
import sys
from setuptools import setup, find_packages, dist
import glob

import torch
from torch.utils.cpp_extension import BuildExtension, CppExtension

PACKAGE_NAME = 'sdfdes'
LICENSE = 'MIT License'
AUTHOR = 'Towaki Takikawa and Joey Litalien'

def get_extensions():
    extra_compile_args = {'cxx': ['-O3']} 
    define_macros = []
    include_dirs = []
    extensions = []
    sources = glob.glob('sdfdes/csrc/**/*.cpp', recursive=True)
 
    if len(sources) == 0:
        print("No source files found for extension, skipping extension compilation")
        return None

    extension = CppExtension

    extensions.append(
        extension(
            name='sdfdes._C',
            sources=sources,
            define_macros=define_macros,
            extra_compile_args=extra_compile_args,
        )
    )

    return extensions

if __name__ == '__main__':
    setup(
        # Metadata
        name=PACKAGE_NAME,
        author=AUTHOR,
        license=LICENSE,
        python_requires='>=3.8',

        # Package info
        packages=['sdfdes'] + find_packages(),
        install_requires=['torch'],
        include_package_data=True,
        zip_safe=True,
        ext_modules=get_extensions(),
        cmdclass={
            'build_ext': BuildExtension.with_options(no_python_abi_suffix=True)    
        }

    )
