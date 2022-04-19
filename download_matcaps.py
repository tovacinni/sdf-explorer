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

import wget

matcap_paths = {
    "Automotive/Red.png" : "https://raw.githubusercontent.com/nidorx/matcaps/master/1024/6D1616_E6CDBA_DE2B24_230F0F.png",
    "Clay/Blue.png" : "https://raw.githubusercontent.com/nidorx/matcaps/master/1024/6C8996_14223F_B9DEDD_2E445C.png",
    "Metal/Aluminium.png" : "https://raw.githubusercontent.com/nidorx/matcaps/master/1024/C7C7D7_4C4E5A_818393_6C6C74.png",
    "Plastic/Red.png" : "https://raw.githubusercontent.com/nidorx/matcaps/master/1024/9D282A_38191D_DFC6CD_D6495A.png",
    "Toon/Gray.png" : "https://market-assets.fra1.cdn.digitaloceanspaces.com/market-assets/materials/toon/toon.jpg"
}

matcap_dir = "data-files/matcap"

if not os.path.exists(matcap_dir):
    os.makedirs(matcap_dir)

for matcap_path in matcap_paths:
    url = matcap_paths[matcap_path] 
    
    category = matcap_path.split("/")[0]

    if not os.path.exists(os.path.join(matcap_dir, category)):
        os.makedirs(os.path.join(matcap_dir, category))
    try:
        wget.download(url, out=os.path.join(matcap_dir, matcap_path))
    except:
        print(f"Downloading from {matcap_path} from {url} failed.")

