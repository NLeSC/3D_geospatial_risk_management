#!/usr/bin/env python
""" Point-in-Polygon host/device code tuner

This program is used for auto-tuning the host and device code of a CUDA program
for computing the point-in-polygon problem for very large datasets and large
polygons.

The time measurements used as a basis for tuning include the time spent on
data transfers between host and device memory. The host code uses device mapped
host memory to overlap communication between host and device with kernel
execution on the GPU. Because each input is read only once and each output
is written only once, this implementation almost fully overlaps all
communication and the kernel execution time dominates the total execution time.

The code has the option to precompute all polygon line slopes on the CPU and
reuse those results on the GPU, instead of recomputing them on the GPU all
the time. The time spent on precomputing these values on the CPU is also
taken into account by the time measurement in the code.

This code was written for use with the Kernel Tuner. See:
     https://github.com/benvanwerkhoven/kernel_tuner

Author: Ben van Werkhoven <b.vanwerkhoven@esciencecenter.nl>
"""
from __future__ import print_function

from collections import OrderedDict
import numpy

from context import get_kernel_path
import kernel_tuner

import os

def tune_pnpoly():

    #change to dir with source files because of includes in pnpoly_host.cu
    os.chdir(get_kernel_path())

    with open('pnpoly_host.cu', 'r') as f:
        host_string = f.read()
    with open('pnpoly.cu', 'r') as f:
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

    args = [bitmap, points, vertex_xy, size]

    tune_params = OrderedDict()

    #tune_params["block_size_x"] = [2**i for i in range(6,10)]   #powers of two
    tune_params["block_size_x"] = [32*i for i in range(1,32)]  #multiple of 32

    tune_params["tile_size"] = [2**i for i in range(6)]
    tune_params["f_unroll"] = [i for i in range(1,20) if float(vertices)/i==vertices//i]
    tune_params["between_method"] = [0, 1, 2, 3]
    tune_params["use_precomputed_slopes"] = [0, 1]
    tune_params["use_method"] = [0, 1]

    grid_div_x = ["block_size_x", "tile_size"]

    #compute a reference answer using naive kernel
    params = {"block_size_x": 512}
    result = kernel_tuner.run_kernel("cn_pnpoly_naive", kernel_string,
        problem_size, [bitmap, points, size], params, cmem_args={"d_vertices": vertex_xy})
    result = [result[0], None, None]

    #start tuning
    results = kernel_tuner.tune_kernel("cn_pnpoly_host", host_string,
        problem_size, args, tune_params,
        grid_div_x=grid_div_x, answer=result, lang="C", verbose=True)

    return results, tune_params


if __name__ == "__main__":
    tune_pnpoly()
