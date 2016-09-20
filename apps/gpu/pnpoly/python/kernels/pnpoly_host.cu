#include <stdio.h>
#include <cuda.h>

#include "pnpoly.cu"

#define max_streams 1

/*
 * This function contains the host code for benchmarking the cn_pnpoly CUDA kernel
 * Including the time spent on data transfers between host and device memory
 *
 * This host code uses device mapped host memory to overlap communication
 * between host and device with kernel execution on the GPU. Because each input
 * is read only once and each output is written only once, this implementation
 * almost fully overlaps all communication and the kernel execution time dominates
 * the total execution time.
 *
 * The code has the option to precompute all polygon line slopes on the CPU and
 * reuse those results on the GPU, instead of recomputing them on the GPU all
 * the time. The time spent on precomputing these values on the CPU is also 
 * taken into account by the time measurement in the code below. 
 *
 * This code was written for use with the Kernel Tuner. See: 
 *      https://github.com/benvanwerkhoven/kernel_tuner
 *
 * Author: Ben van Werkhoven <b.vanwerkhoven@esciencecenter.nl>
 */
float cn_pnpoly_host(int* bitmap, float2* points, float2* vertices, int n) {

    cudaError_t err;
    float2 *h_vertices;
    float *h_slopes;
    float2 *h_points;
    int *h_bitmap;

    //Allocate pinned and aligned host memory and copy input data
    err = cudaHostAlloc((void **)&h_vertices, VERTICES*sizeof(float2), cudaHostAllocMapped);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaHostAlloc: %s\n", cudaGetErrorString(err));
    }
    err = cudaHostAlloc((void **)&h_slopes, VERTICES*sizeof(float), cudaHostAllocMapped);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaHostAlloc: %s\n", cudaGetErrorString(err));
    }
    err = cudaHostAlloc((void **)&h_points, block_size_x*tile_size*grid_size_x*sizeof(float2), cudaHostAllocMapped);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaHostAlloc: %s\n", cudaGetErrorString(err));
    }
    err = cudaHostAlloc((void **)&h_bitmap, block_size_x*tile_size*grid_size_x*sizeof(int), cudaHostAllocMapped);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaHostAlloc: %s\n", cudaGetErrorString(err));
    }
    memcpy(h_vertices, vertices, VERTICES*sizeof(float2));
    memcpy(h_points, points, n*sizeof(float2));

    //create CUDA streams and events
    cudaStream_t stream[max_streams];
    for (int i=0; i<max_streams; i++) {
        err = cudaStreamCreate(&stream[i]);
        if (err != cudaSuccess) {
            fprintf(stderr, "Error in cudaStreamCreate: %s\n", cudaGetErrorString(err));
        }
    }
    cudaEvent_t start;
    err = cudaEventCreate(&start);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaEventCreate: %s\n", cudaGetErrorString(err));
    }

    cudaEvent_t stop;
    err = cudaEventCreate(&stop);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaEventCreate: %s\n", cudaGetErrorString(err));
    }

    //kernel parameters
    dim3 threads(block_size_x, block_size_y, block_size_z);
    dim3 grid(grid_size_x, grid_size_y);

    //start measuring time
    cudaDeviceSynchronize();
    cudaEventRecord(start, stream[0]);

    //transfer vertices to d_vertices
    err = cudaMemcpyToSymbolAsync(d_vertices, h_vertices, VERTICES*sizeof(float2), 0, cudaMemcpyHostToDevice, stream[0]);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaMemcpyToSymbolAsync: %s\n", cudaGetErrorString(err));
    }

    #if use_precomputed_slopes == 1
    //precompute the slopes and transfer to symbol d_slopes
    h_slopes[0] = (h_vertices[VERTICES-1].x - h_vertices[0].x) / (h_vertices[VERTICES-1].y - h_vertices[0].y);
    for (int i=1; i<VERTICES; i++) {
        h_slopes[i] = (h_vertices[i-1].x - h_vertices[i].x) / (h_vertices[i-1].y - h_vertices[i].y);
    }
    err = cudaMemcpyToSymbolAsync(d_slopes, h_slopes, VERTICES*sizeof(float), 0, cudaMemcpyHostToDevice, stream[0]);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaMemcpyToSymbolAsync: %s\n", cudaGetErrorString(err));
    }
    #endif

    //call the kernel
    cn_pnpoly<<<grid, threads, 0, stream[0]>>>(h_bitmap, h_points, n);  //using mapped memory

    //stop time measurement
    cudaEventRecord(stop, stream[0]);
    cudaDeviceSynchronize();
    float time = 0.0;
    cudaEventElapsedTime(&time, start, stop);

    err = cudaGetLastError();
    if (err != cudaSuccess) {
        fprintf(stderr, "Cuda error after kernel: %s.\n", cudaGetErrorString(err));
    }

    //copy data back to output parameter for correctness checking
    memcpy(bitmap, h_bitmap, n*sizeof(int));

    //cleanup
    cudaFreeHost(h_points);
    cudaFreeHost(h_vertices);
    cudaFreeHost(h_slopes);
    cudaFreeHost(h_bitmap);
    for (int i=0; i<max_streams; i++) {
        err = cudaStreamDestroy(stream[i]);
    }
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return time; //ms
}
