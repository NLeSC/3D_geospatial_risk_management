// CUDA runtime
#include <cuda.h>
#include <cuda_runtime.h>

// helper functions and utilities to work with CUDA
#include <helper_functions.h>
#include <helper_cuda.h>

extern "C" {
#include "g_pnpoly.h"
}

// Cuda version
__global__ void pnpoly_cnGPU(const float *px, const float *py, const float *vx, const float *vy, char* cs, int npoint, int nvert)
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
    bool bPinGenericMemory = true;                 // Allocate generic memory with malloc() and pin it later instead of using cudaHostAlloc()
    unsigned int flags;
    size_t pbytes, vbytes, cbytes;
    float *px, *py, *vx, *vy;
    //float *px_UA, *py_UA, *vx_UA, *vy_UA;          // Non-4K Aligned Pinned memory on the CPU
    float *d_px, *d_py, *d_vx, *d_vy;              // Device pointers for mapped memory
    char *c, *c_UA, *d_c;                            // Device pointers for mapped memory
    struct timeval stop, start;
    unsigned long long t;
    int i, count = 0;

    /*CUDA monitoring*/
    cudaEvent_t cstart, cstop;

	/*
	if (GPU_SETUP != 1) {
        printf("> GPU_SETUP was not initialized.\n");
		setup_GPU();
	}
	*/

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

    if (bPinGenericMemory) {
#if CUDART_VERSION >= 4000
        gettimeofday(&start, NULL);
        /*
        px_UA = (float *) malloc(pbytes + MEMORY_ALIGNMENT);
        py_UA = (float *) malloc(pbytes + MEMORY_ALIGNMENT);
        vx_UA = (float *) malloc(vbytes + MEMORY_ALIGNMENT);
        vy_UA = (float *) malloc(vbytes + MEMORY_ALIGNMENT);
        c_UA = (char *) malloc(cbytes + MEMORY_ALIGNMENT);

        // We need to ensure memory is aligned to 4K (so we will need to padd memory accordingly)
        px = (float *) ALIGN_UP(px_UA, MEMORY_ALIGNMENT);
        py = (float *) ALIGN_UP(py_UA, MEMORY_ALIGNMENT);
        vx = (float *) ALIGN_UP(vx_UA, MEMORY_ALIGNMENT);
        vy = (float *) ALIGN_UP(vy_UA, MEMORY_ALIGNMENT);
        */
        c_UA = (char *) malloc(cbytes + MEMORY_ALIGNMENT);
        c = (char *) ALIGN_UP(c_UA, MEMORY_ALIGNMENT);
		/*
        px = (float *) ALIGN_UP(mpx, MEMORY_ALIGNMENT);
        py = (float *) ALIGN_UP(mpy, MEMORY_ALIGNMENT);
        vx = (float *) ALIGN_UP(mvx, MEMORY_ALIGNMENT);
        vy = (float *) ALIGN_UP(mvy, MEMORY_ALIGNMENT);
        */

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
#endif
    }

	/*Copy point and vertices*/
    gettimeofday(&start, NULL);
	//memcpy(px, mpx, pbytes); 
	//memcpy(py, mpy, pbytes); 
	//memcpy(vx, mvx, vbytes); 
	//memcpy(vy, mvy, vbytes); 
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("MemCopy took %llu ms\n", t);

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
    //vectorAddGPU<<<grid, block>>>(d_a, d_b, d_c, nelem);
    //gettimeofday(&start, NULL);
    
    //pnpoly_cnGPU<<<grid, block>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);
    //size_t sh_size = 2*607*sizeof(float);
    //pnpoly_cnGPU<<<grid, block,sh_size>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);

    cudaEventCreate(&cstart);
    cudaEventCreate(&cstop);
    cudaEventRecord(cstart);
    size_t sh_size = 2*nvert*sizeof(float);
    pnpoly_cnGPU<<<grid, block, sh_size>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);
    cudaEventRecord(cstop);

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
    //    free(px_UA);
    //    free(py_UA);
    //    free(vx_UA);
    //    free(vy_UA);
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
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("Output results %llu ms\n", t);

    return 0;
}

