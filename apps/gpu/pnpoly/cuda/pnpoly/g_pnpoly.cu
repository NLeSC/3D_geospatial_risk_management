// CUDA runtime
#include <cuda.h>
#include <cuda_runtime.h>

// helper functions and utilities to work with CUDA
#include <helper_functions.h>
#include <helper_cuda.h>

extern "C" {
#include "g_pnpoly.h"
}

#define VERTICES 2000

#ifndef between_method
#define between_method 1
#endif

#ifndef use_method
#define use_method 1
#endif

#ifndef block_size_x
#define block_size_x 256
#endif
#ifndef block_size_y
#define block_size_y 1
#endif
#ifndef block_size_z
#define block_size_z 1
#endif

#ifndef tile_size
#define tile_size 1
#endif

#define max_streams 1
__constant__ float d_verticesX[VERTICES];
__constant__ float d_verticesY[VERTICES];
__constant__ float d_slopes[VERTICES];

__device__ __forceinline__ int is_between(float a, float b, float c) {
    #if between_method == 0
        return (b > a) != (c > a);
    #elif between_method == 1
        return ((b <= a) && (c > a)) || ((b > a) && (c <= a));
    #elif between_method == 2
        return ((a - b) == 0.0f) || ((a - b) * (a - c) < 0.0f);
    #elif between_method == 3
        //Interestingly enough method 3 exactly the same as method 2, only in a different order.
        //the performance difference between method 2 and 3 can be huge depending on all the other optimization parameters.
        return ((a - b) * (a - c) < 0.0f) || (a - b == 0.0f);
    #endif
}

__global__ void cn_pnpolyBEN(char* bitmap, float *px, float *py, int npoints, int nverts) {
    int i = blockIdx.x * block_size_x * tile_size + threadIdx.x;
    if (i < npoints) {

        char c[tile_size];
        float2 lpoints[tile_size];
        #pragma unroll
        for (int ti=0; ti<tile_size; ti++) {
            c[ti] = 0;
            lpoints[ti] = make_float2(px[i+block_size_x*ti], py[i+block_size_x*ti]);
        }

        int k = nverts-1;

        for (int j=0; j<nverts; k = j++) {    // edge from vj to vk
            float2 vj = make_float2(d_verticesX[j], d_verticesY[j]); 
            float2 vk = make_float2(d_verticesX[k], d_verticesY[k]); 

            #if use_precomputed_slopes == 0
            float slope = (vk.x-vj.x) / (vk.y-vj.y);
            #elif use_precomputed_slopes == 1
            float slope = d_slopes[j];
            #endif

            #pragma unroll
            for (int ti=0; ti<tile_size; ti++) {

                float2 p = lpoints[ti];

                #if use_method == 0
                if ( is_between(p.y, vj.y, vk.y) &&         //if p is between vj and vk vertically
                     (p.x < slope * (p.y-vj.y) + vj.x) ) {  //if p.x crosses the line vj-vk when moved in positive x-direction
                    c[ti] = !c[ti];
                }

                #elif use_method == 1
                //Same as method 0, but attempts to reduce divergence by avoiding the use of an if-statement.
                //Whether this is more efficient is data dependent because there will be no divergence using method 0, when none
                //of the threads within a warp evaluate is_between as true
                int b = is_between(p.y, vj.y, vk.y);
                c[ti] += b && (p.x < vj.x + slope * (p.y - vj.y));

                #endif


            }

        }

        #pragma unroll
        for (int ti=0; ti<tile_size; ti++) {
            //could do an if statement here if 1s are expected to be rare
            #if use_method == 0
            bitmap[i+block_size_x*ti] = c[ti];
            #elif use_method == 1
            bitmap[i+block_size_x*ti] = c[ti] & 1;
            #endif
        }
    }
}


// Cuda version
__global__ void pnpoly_cnGPU(char *cs, const float *px, const float *py, const float *vx, const float *vy, int npoint, int nvert)
{
    extern __shared__ int s[];
    float *tvx = (float*) s;
   	float *tvy = (float*)&s[nvert];

    int i = blockIdx.x*blockDim.x + threadIdx.x;
    if (i < npoint) {
        int j, k, c = 0;
    	for (j = 0, k = nvert-1; j < nvert; k = j++) {
        	tvx[j] = vx [j];
        	tvy[j] = vy [j];
    	}

    	__syncthreads();

        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            if ( ((tvy[j]>py[i]) != (tvy[k]>py[i])) &&
                    (px[i] < (tvx[k]-tvx[j]) * (py[i]-tvy[j]) / (tvy[k]-tvy[j]) + tvx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
    }
}

__global__ void pnpoly_cnGPU1(const float *px, const float *py, const float *vx, const float *vy, char* cs, int npoint, int nvert)
{
    int i = blockIdx.x*blockDim.x + threadIdx.x;
    if (i < npoint) {
        int j, k, c = 0;
        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            if ( ((vy[j]>py[i]) != (vy[k]>py[i])) &&
                    (px[i] < (vx[k]-vx[j]) * (py[i]-vy[j]) / (vy[k]-vy[j]) + vx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
    }
}

__global__ void pnpoly_cnGPU2(const float *px, const float *py, const float *vx, const float *vy, char* cs, int npoint, int nvert)
{
    int i = blockIdx.x*blockDim.x + threadIdx.x;
    __shared__ float tpx;
    __shared__ float tpy;
    if (i < npoint) {
        tpx = px[i];
        tpy = py[i];
        int j, k, c = 0;
        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            if ( ((vy[j]>tpy) != (vy[k]>tpy)) &&
                    (tpx < (vx[k]-vx[j]) * (tpy-vy[j]) / (vy[k]-vy[j]) + vx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
        __syncthreads();
    }
}

/* Add two vectors on the GPU */
__global__ void vectorAddGPU(float *a, float *b, float *c, int N)
{
    int idx = blockIdx.x*blockDim.x + threadIdx.x;

    if (idx < N)
    {
        c[idx] = a[idx] + b[idx];
    }
}


extern "C"

int setup_GPU() {
    int idev = 0;                                   // use default device 0
    cudaDeviceProp deviceProp;

	//GPU_SETUP = 0;

    /*
     * if GPU found supports SM 1.2, then continue, otherwise we exit
	*/
    if (!checkCudaCapabilities(1, 2)) {
        exit(EXIT_SUCCESS);
    }

    checkCudaErrors(cudaSetDevice(idev));

    /* Verify the selected device supports mapped memory and set the device
       flags for mapping host memory. */
    checkCudaErrors(cudaGetDeviceProperties(&deviceProp, idev));

#if CUDART_VERSION >= 2020
    if (!deviceProp.canMapHostMemory) {
        fprintf(stderr, "Device %d does not support mapping CPU host memory!\n", idev);
        cudaDeviceReset();
        exit(EXIT_SUCCESS);
    }
    checkCudaErrors(cudaSetDeviceFlags(cudaDeviceMapHost));
#else
    fprintf(stderr, "CUDART version %d.%d does not support <cudaDeviceProp.canMapHostMemory> field\n", , CUDART_VERSION/1000, (CUDART_VERSION%100)/10);
    cudaDeviceReset();
    exit(EXIT_SUCCESS);
#endif

#if CUDART_VERSION < 4000
    if (bPinGenericMemory) {
        fprintf(stderr, "CUDART version %d.%d does not support <cudaHostRegister> function\n", CUDART_VERSION/1000, (CUDART_VERSION%100)/10);
        cudaDeviceReset();
        exit(EXIT_SUCCESS);
    }
#endif

	//GPU_SETUP = 1;

	return 0;
}

void reset_GPU() {
    cudaDeviceReset();
}

int pnpoly_GPU(signed char **mc, int nvert, int npoint, float *mpx, float *mpy, float *mvx, float *mvy) {
    /*GPU*/
    bool bPinGenericMemory = false;                 // Allocate generic memory with malloc() and pin it later instead of using cudaHostAlloc()
    unsigned int flags;
    size_t pbytes, vbytes, cbytes;
    float *px, *py, *vx, *vy;
    float *d_px, *d_py, *d_vx, *d_vy;              // Device pointers for mapped memory
    char *c, *c_UA, *d_c;                            // Device pointers for mapped memory
    struct timeval stop, start;
    unsigned long long t;
    int i, count = 0;
    float *h_slopes;
    cudaError_t err;

    //create CUDA streams and events
    cudaStream_t stream[max_streams];
    for (int i=0; i<max_streams; i++) {
        err = cudaStreamCreate(&stream[i]);
        if (err != cudaSuccess) {
            fprintf(stderr, "Error in cudaStreamCreate: %s\n", cudaGetErrorString(err));
        }
    }
    /*CUDA monitoring*/
    cudaEvent_t cstart, cstop;

    if (bPinGenericMemory) {
	/*Return str with the error*/
        printf("> Using Generic System Paged Memory (malloc)\n");
    } else {
	/*Return str with the error*/
        printf("> Using CUDA Host Allocated (cudaHostAlloc)\n");
    }

    pbytes = npoint*sizeof(float);
    vbytes = nvert*sizeof(float);
    cbytes = npoint*sizeof(char);
    printf("Bytes allocated for npoints %d and nvert %d: pbytes %zu, vbytes %zu, cbytes %zu\n", npoint, nvert, pbytes, vbytes, cbytes);

    err = cudaHostAlloc((void **)&h_slopes, nvert*sizeof(float), cudaHostAllocMapped);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaHostAlloc: %s\n", cudaGetErrorString(err));
    }

    if (bPinGenericMemory) {
#if CUDART_VERSION >= 4000
        gettimeofday(&start, NULL);
        c_UA = (char *) malloc(cbytes + MEMORY_ALIGNMENT);
        c = (char *) ALIGN_UP(c_UA, MEMORY_ALIGNMENT);

        px = mpx;
        py = mpy;
        vx = mvx;
        vy = mvy;

        checkCudaErrors(cudaHostRegister(px, pbytes, CU_MEMHOSTALLOC_DEVICEMAP));
        checkCudaErrors(cudaHostRegister(py, pbytes, CU_MEMHOSTALLOC_DEVICEMAP));
        checkCudaErrors(cudaHostRegister(vx, vbytes, CU_MEMHOSTALLOC_DEVICEMAP));
        checkCudaErrors(cudaHostRegister(vy, vbytes, CU_MEMHOSTALLOC_DEVICEMAP));
        checkCudaErrors(cudaHostRegister(c, cbytes, CU_MEMHOSTALLOC_DEVICEMAP));
        gettimeofday(&stop, NULL);
        t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
        printf("PinGenericMemory took %llu ms\n", t);
#endif
    } else {
#if CUDART_VERSION >= 2020
        flags = cudaHostAllocMapped;
        checkCudaErrors(cudaHostAlloc((void **)&px, pbytes, flags));
        checkCudaErrors(cudaHostAlloc((void **)&py, pbytes, flags));
        checkCudaErrors(cudaHostAlloc((void **)&vx, vbytes, flags));
        checkCudaErrors(cudaHostAlloc((void **)&vy, vbytes, flags));
        checkCudaErrors(cudaHostAlloc((void **)&c, cbytes, flags));

		/*Copy point and vertices*/
    	gettimeofday(&start, NULL);
		memcpy(px, mpx, pbytes); 
		memcpy(py, mpy, pbytes); 
		memcpy(vx, mvx, vbytes); 
		memcpy(vy, mvy, vbytes); 
    	gettimeofday(&stop, NULL);
    	t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    	printf("MemCopy took %llu ms\n", t);

#endif
    }

    //transfer vertices to d_vertices
    err = cudaMemcpyToSymbolAsync(d_verticesX, vx, nvert*sizeof(float), 0, cudaMemcpyHostToDevice, stream[0]);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaMemcpyToSymbolAsync: %s\n", cudaGetErrorString(err));
    }
    err = cudaMemcpyToSymbolAsync(d_verticesY, vy, nvert*sizeof(float), 0, cudaMemcpyHostToDevice, stream[0]);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaMemcpyToSymbolAsync: %s\n", cudaGetErrorString(err));
    }

    #if use_precomputed_slopes == 1
    //precompute the slopes and transfer to symbol d_slopes
    h_slopes[0] = (vx[nvert-1] - vx[0]) / (vy[nvert-1] - vy[0]);
    for (int i=1; i<nvert; i++) {
        h_slopes[i] = (vx[i-1] - vx[i]) / (vy[i-1] - vy[i]);
    }
    err = cudaMemcpyToSymbolAsync(d_slopes, h_slopes, nvert*sizeof(float), 0, cudaMemcpyHostToDevice, stream[0]);
    if (err != cudaSuccess) {
        fprintf(stderr, "Error in cudaMemcpyToSymbolAsync: %s\n", cudaGetErrorString(err));
    }
    #endif

    /* Get the device pointers for the pinned CPU memory mapped into the GPU
       memory space. */
#if CUDART_VERSION >= 2020
    gettimeofday(&start, NULL);
    checkCudaErrors(cudaHostGetDevicePointer((void **)&d_px, (void *)px, 0));
    checkCudaErrors(cudaHostGetDevicePointer((void **)&d_py, (void *)py, 0));
    checkCudaErrors(cudaHostGetDevicePointer((void **)&d_vx, (void *)vx, 0));
    checkCudaErrors(cudaHostGetDevicePointer((void **)&d_vy, (void *)vy, 0));
    checkCudaErrors(cudaHostGetDevicePointer((void **)&d_c, (void *)c, 0));
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("Get devie pointers took %llu ms\n", t);
#endif

    /* Call the GPU kernel using the CPU pointers residing in CPU mapped memory. */
    printf("> pnpoly_GPU kernel will check which points are in the Polygon using mapped CPU memory...\n");
    //dim3 block(256);
    dim3 block(BLOCK_SIZE);
    dim3 grid((unsigned int)ceil(npoint/(float)block.x));

    cudaEventCreate(&cstart);
    cudaEventCreate(&cstop);
    cudaEventRecord(cstart, stream[0]);
    //size_t sh_size = 2*nvert*sizeof(float);
    //pnpoly_cnGPU<<<grid, block, sh_size>>>(d_c, d_px, d_py, d_vx, d_vy, npoint, nvert);

    dim3 threads(block_size_x, block_size_y, block_size_z);
	cn_pnpolyBEN<<<grid, threads, 0, stream[0]>>>(d_c, d_px, d_py, npoint, nvert);
    cudaEventRecord(cstop, stream[0]);

    checkCudaErrors(cudaDeviceSynchronize());
    getLastCudaError("pnpoly_cnGPU() execution failed");

    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;

    cudaEventSynchronize(cstop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, cstart, cstop);

    printf("PnPoly took %llu ms and %f msecs CUDA\n", t, milliseconds);

    gettimeofday(&start, NULL);
    /* Output results */
	for (i = 0; i < cbytes; i++) {
		char is = c[i];
		if (is == 1)
			count++;
	}
	printf("It has %d\n", count);
    memcpy(*mc, c, cbytes);

    /* Memory clean up */
    printf("> Releasing CPU memory...\n");

    if (bPinGenericMemory) {
#if CUDART_VERSION >= 4000
        checkCudaErrors(cudaHostUnregister(px));
        checkCudaErrors(cudaHostUnregister(py));
        checkCudaErrors(cudaHostUnregister(vx));
        checkCudaErrors(cudaHostUnregister(vy));
        checkCudaErrors(cudaHostUnregister(c));
        free(c_UA);
#endif
    } else {
#if CUDART_VERSION >= 2020
        checkCudaErrors(cudaFreeHost(px));
        checkCudaErrors(cudaFreeHost(py));
        checkCudaErrors(cudaFreeHost(vx));
        checkCudaErrors(cudaFreeHost(vy));
        checkCudaErrors(cudaFreeHost(c));
#endif
    }
    cudaFreeHost(h_slopes);
    for (int i=0; i<max_streams; i++) {
        err = cudaStreamDestroy(stream[i]);
    }
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("Output results %llu ms\n", t);

    return 0;
}

