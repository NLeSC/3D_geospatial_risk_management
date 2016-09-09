#!/usr/bin/env python
import numpy
import kernel_tuner

from .context import skip_if_no_cuda_device, get_kernel_path


def test_pnpoly_naive_kernel():

    skip_if_no_cuda_device()

    with open(get_kernel_path()+'pnpoly.cu', 'r') as f:
        kernel_string = f.read()

    problem_size = (20000, 1)
    size = numpy.int32(numpy.prod(problem_size))
    vertices = 600

    points = numpy.random.randn(2*size).astype(numpy.float32)
    bitmap = numpy.zeros(size).astype(numpy.int32)

    #to verify the output of the gpu kernel
    #we use a circle with radius 1 as polygon and
    #do a simple distance to 0,0 check for all points

    vertex_seeds = numpy.sort(numpy.random.rand(vertices)*2.0*numpy.pi)[::-1]

    points_x = points[::2]
    points_y = points[1::2]

    print "points_x min max", points_x.min(), points_x.max()
    print "points_y min max", points_y.min(), points_y.max()

    vertex_x = numpy.cos(vertex_seeds)
    vertex_x[-1] = vertex_x[0]
    vertex_y = numpy.sin(vertex_seeds)
    vertex_y[-1] = vertex_y[0]
    vertex_xy = numpy.array( zip(vertex_x, vertex_y) ).astype(numpy.float32)

    args = [bitmap, points, size]

    print "vertex_x min max", vertex_x.min(), vertex_x.max()
    print "vertex_y min max", vertex_y.min(), vertex_y.max()

    #from matplotlib import pyplot
    #plot all points
    #pyplot.scatter(points_x, points_y)
    #plot the outline of the polygon
    #pyplot.plot(vertex_x, vertex_y)
    #pyplot.show()

    cmem_args= {'d_vertices': vertex_xy }

    params = dict()
    params["block_size_x"] = 512

    kernel_name = "cn_pnpoly_naive"

    #compute kernel output
    result = kernel_tuner.run_kernel(kernel_name, kernel_string,
        problem_size, args, params,
        cmem_args=cmem_args)

    answer = result[0]
    answer_sum = numpy.sum(answer)
    print("answer sum=", answer_sum)
    print(result[0])

    #compute reference answer
    reference = [numpy.sqrt(x*x + y*y) < 1.0 for x,y in zip(points_x, points_y)]
    reference = numpy.array(reference).astype(numpy.int32)
    reference_sum = numpy.sum(reference)
    print("reference sum =", reference_sum)
    print(reference)

    #we assert with a small margin because the test
    #and the kernel compute different things
    assert numpy.sum(numpy.absolute(answer - reference)) < 5

