#!/usr/bin/env python
from __future__ import print_function

from collections import OrderedDict
import numpy

from context import get_kernel_path
import kernel_tuner

def tune_pnpoly_kernel():

    with open(get_kernel_path()+'pnpoly.cu', 'r') as f:
        kernel_string = f.read()

    size = numpy.int32(2e7)
    problem_size = (size, 1)
    vertices = 600

    points = numpy.random.randn(2*size).astype(numpy.float32)
    bitmap = numpy.zeros(size).astype(numpy.int32)

    #as test input we use a circle with radius 1 as polygon and
    #a large set of normally distributed points around 0,0

    vertex_seeds = numpy.sort(numpy.random.rand(vertices)*2.0*numpy.pi)[::-1]

    points_x = points[::2]
    points_y = points[1::2]

    vertex_x = numpy.cos(vertex_seeds)
    vertex_y = numpy.sin(vertex_seeds)
    vertex_xy = numpy.array( zip(vertex_x, vertex_y) ).astype(numpy.float32)

    args = [bitmap, points, size]

    # (vk.x-vj.x) / (vk.y-vj.y)
    slopes = numpy.zeros(vertices).astype(numpy.float32)
    for i in range(len(slopes)):
        if i == 0:
            slopes[i] = (vertex_x[-1] - vertex_x[i]) / (vertex_y[-1] - vertex_y[i])
        else:
            slopes[i] = (vertex_x[i-1] - vertex_x[i]) / (vertex_y[i-1] - vertex_y[i])

    cmem_args= {'d_vertices': vertex_xy, "d_slopes": slopes }

    tune_params = OrderedDict()

    tune_params["block_size_x"] = [2**i for i in range(6,10)]   #powers of two
    #tune_params["block_size_x"] = [32*i for i in range(1,32)]  #multiple of 32
    #tune_params["block_size_x"] = [256]                        #fixed size

    tune_params["tile_size"] = [2**i for i in range(6)]
    #tune_params["f_unroll"] = [i for i in range(1,20) if float(vertices)/i==vertices//i]
    tune_params["between_method"] = [0, 1, 2, 3]
    tune_params["use_precomputed_slopes"] = [0, 1]
    tune_params["use_method"] = [0, 1]

    grid_div_x = ["block_size_x", "tile_size"]

    #compute a reference answer using naive kernel
    params = {"block_size_x": 512}
    result = kernel_tuner.run_kernel("cn_pnpoly_naive", kernel_string,
        problem_size, args, params, cmem_args=cmem_args)
    result = [result[0], None, None]

    #start tuning
    results = kernel_tuner.tune_kernel("cn_pnpoly", kernel_string,
        problem_size, args, tune_params,
        grid_div_x=grid_div_x, cmem_args=cmem_args, answer=result)

    return results, tune_params


if __name__ == "__main__":
    tune_pnpoly_kernel()
