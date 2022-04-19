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

#include <vector>
#include <fstream>
#include <ATen/ATen.h>

namespace sdfdes {

std::vector<at::Tensor> deserialize(std::string filename) {

    // Open stream to read input
    std::ifstream f(filename, std::ios::binary);
    
    uint32_t n;
    f.read((char*)&n, sizeof(uint32_t));

    at::Tensor position_tensor = at::zeros({n, 3}, at::TensorOptions().dtype(at::kFloat));
    at::Tensor distance_tensor = at::zeros({n, 1}, at::TensorOptions().dtype(at::kFloat));
    at::Tensor gradient_tensor = at::zeros({n, 3}, at::TensorOptions().dtype(at::kFloat));

    auto *position_ptr = position_tensor.data_ptr<float>();
    auto *distance_ptr = distance_tensor.data_ptr<float>();
    auto *gradient_ptr = gradient_tensor.data_ptr<float>();

    // Retrieve tensor index
    auto idx2  = [&](int i, int j) -> size_t { return i*3 + j; };

    // Serially read samples, one at a time
    for (uint32_t i = 0; i < n; i++) {
        // Read XYZ position
        float position[3];
        f.read((char*)&position[0], 3 * sizeof(float));
        position_ptr[idx2(i, 0)] = position[0];
        position_ptr[idx2(i, 1)] = position[1];
        position_ptr[idx2(i, 2)] = position[2];
    }
    for (uint32_t i = 0; i < n; i++) {
        // Read signed distance
        float dist;
        f.read((char*)&dist, 1 * sizeof(float));
        distance_ptr[i] = dist;
    }
    for (uint32_t i = 0; i < n; i++) {
        // Read normals
        float gradient[3];
        f.read((char*)&gradient[0], 3 * sizeof(float));
        gradient_ptr[idx2(i, 0)] = gradient[0];
        gradient_ptr[idx2(i, 1)] = gradient[1];
        gradient_ptr[idx2(i, 2)] = gradient[2];
    }

    f.close();
    return {position_tensor, distance_tensor, gradient_tensor};

}

}

