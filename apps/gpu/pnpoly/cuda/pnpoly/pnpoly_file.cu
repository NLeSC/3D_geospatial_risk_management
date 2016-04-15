// System includes
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

// CUDA runtime
#include <cuda.h>
#include <cuda_runtime.h>

// helper functions and utilities to work with CUDA
#include <helper_functions.h>
#include <helper_cuda.h>

#ifndef MAX 
#define MAX(a,b) (a > b ? a : b) 
#endif

#define THREADS_PER_BLOCK 512
#define BLOCK_SIZE 256

#define cudaDeviceScheduleBlockingSync   0x04 

int pnpoly_cn(char **res, int nvert, float *vx, float *vy, int npoint, float *px, float *py)
{
    int i = 0;
    char *cs = NULL;
    cs = *res;

    for (i = 0; i < npoint; i++) {
        int j, k, c = 0;
        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            if ( ((vy[j]>py[i]) != (vy[k]>py[i])) &&
                    (px[i] < (vx[k]-vx[j]) * (py[i]-vy[j]) / (vy[k]-vy[j]) + vx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
    }

    return 0;
}

float isLeft( float P0x, float P0y, float P1x, float P1y, float P2x, float P2y)
{
    return ( (P1x - P0x) * (P2y - P0y) - (P2x -  P0x) * (P1y - P0y) );
}

int pnpoly_wn(char **res, int nvert, float *vx, float *vy, int npoint, float *px, float *py)
{
    int i = 0, j =0;
    char *cs = NULL;
    cs = *res;

    for (i = 0; i < npoint; i++) {
        int wn = 0;
        for (j = 0; j < nvert-1; j++) {
            if (vy[j] <= py[i]) {
                if (vy[j+1] > py[i])
                    if (isLeft( vx[j], vy[j], vx[j+1], vy[j+1], px[i], py[i]) > 0)
                        ++wn;
            }
            else {
                if (vy[j+1]  <= py[i])
                    if (isLeft( vx[j], vy[j], vx[j+1], vy[j+1], px[i], py[i]) < 0)
                        --wn;
            }
        }
        cs[i] = wn & 1;
        //cs[i] = wn;
    }

    return 0;
}

int pnpoly_wnLeft(int **res, int nvert, float *vx, float *vy, int npoint, float *px, float *py)
{
    int i = 0, j =0;
    int *cs = NULL;
    cs = *res;

    for (i = 0; i < npoint; i++) {
        int wn = 0;
        for (j = 0; j < nvert-1; j++) {
            if (vy[j] <= py[i]) {
                if (vy[j+1] > py[i])
                    //if (isLeft( vx[j], vy[j], vx[j+1], vy[j+1], px[i], py[i]) > 0)
                    if (( (vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j]) ) > 0)
                        ++wn;
            }
            else {
                if (vy[j+1]  <= py[i])
                    //if (isLeft( vx[j], vy[j], vx[j+1], vy[j+1], px[i], py[i]) < 0)
                    if (( (vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j]) ) < 0)
                        --wn;
            }
        }
        cs[i] = wn & 1;
        //cs[i] = wn;
    }

    return 0;
}

int getPoints(char* filename, int npoint, float **px, float **py) {
    FILE *fp = NULL;
    char * line = NULL;
    size_t len = 0;
    ssize_t read = 0;
    int points = 0;
    float *ptx, *pty;

    fp = fopen(filename, "r");

    if (fp == NULL)
        exit(EXIT_FAILURE);

    ptx = *px;
    pty = *py;

    while ((read = getline(&line, &len, fp)) != -1) {
        line[read-1]='\0';
        sscanf(line, "%f %f", &ptx[points], &pty[points]);
        points++;
    }

    fclose(fp);
    if (line)
        free(line);
    if (npoint != points)
        points = 0;

    return points;
}

int outputResult(char *filename, char *cs, int npoint, float *px, float *py) {
    int i = 0;
    FILE *fp = NULL;
    fp = fopen(filename, "w");

    for (i=0; i<npoint; i++) {
        if (cs[i])
            fprintf(fp,"%lf %lf\n", px[i], py[i]);
    }
    fclose(fp);
    return 0;
}

// Modification for the structure, knowing that the first vertex is repeated in the last position of the array
int pnpoly2(int nvert, float *vertex, float testx, float testy)
{
	int i, j, c = 0;
	for (i = 1, j = i-1; i < nvert; j = i++) {
		if ( ((vertex[3*i+1]>testy) != (vertex[3*j+1]>testy)) &&
			(testx < (vertex[3*j]-vertex[3*i]) * (testy-vertex[3*i+1]) / (vertex[3*j+1]-vertex[3*i+1]) + vertex[3*i]) )
			c = !c;
	}
	return c;
}

// Cuda version
__global__ void pnpoly_cnGPU(const float *px, const float *py, const float *vx, const float *vy, char* cs, int npoint, int nvert)
{
    __shared__ float tvx[607];
    __shared__ float tvy[607];

    int i = blockIdx.x*blockDim.x + threadIdx.x;
    if (i < npoint) {
        int j, k, c = 0;
        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            tvx[j] = vx [j];
            tvy[j] = vy [j];
            if ( ((tvy[j]>py[i]) != (tvy[k]>py[i])) &&
                    (px[i] < (tvx[k]-tvx[j]) * (py[i]-tvy[j]) / (tvy[k]-tvy[j]) + tvx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
    }
    __syncthreads();
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



/*function [bool_out] = inpolygon_for_gpu(testx,testy,vertx,verty)


ind1=1;
nvert=length(vertx);
ind2=nvert-1;
bool_out=zeros(size(testx));
while ind1<nvert
        
            bools_to_change=find( ((verty(ind1)>testy) ~= (verty(ind2)>testy)) & ...
                (testx < (vertx(ind2)-vertx(ind1)) * ...
                    (testy-verty(ind1)) / (verty(ind2)-verty(ind1)) + vertx(ind1) ));

                bool_out(bools_to_change)=~bool_out(bools_to_change);
                    ind2=ind1;
                        ind1=ind1+1;
                        end
*/


// Macro to aligned up to the memory size in question
#define MEMORY_ALIGNMENT  4096
#define ALIGN_UP(x,size) ( ((size_t)x+(size-1))&(~(size-1)) )

int main(int argc, char* argv[]){
    int nvert, npoint;
    struct timeval stop, start;
    unsigned long long t;

    /*GPU*/
    int idev = 0;                                   // use default device 0
    bool bPinGenericMemory = true;                 // Allocate generic memory with malloc() and pin it later instead of using cudaHostAlloc()
    cudaDeviceProp deviceProp;
    unsigned int flags;
    size_t pbytes, vbytes, cbytes;
    float *px, *py, *vx, *vy;                  // Pinned memory allocated on the CPU
    float *px_UA, *py_UA, *vx_UA, *vy_UA;          // Non-4K Aligned Pinned memory on the CPU
    float *d_px, *d_py, *d_vx, *d_vy;              // Device pointers for mapped memory
    char *c, *c_UA, *d_c;                            // Device pointers for mapped memory

    /*CUDA monitoring*/
    cudaEvent_t cstart, cstop;

    if (argc != 7) {
        printf("Wrong number of arguments:\n./pnpoly <func [0 for cn | 1 for wn | 2 for wnLeft]> <points_filename> <num_points> <polygon_filename> <num_vertex> <out_filename>\n");
        return 0;
    }

    // if GPU found supports SM 1.2, then continue, otherwise we exit 
    if (!checkCudaCapabilities(1, 2)) {
        exit(EXIT_SUCCESS);
    }

    if (bPinGenericMemory) {
        printf("> Using Generic System Paged Memory (malloc)\n");
    } else {
        printf("> Using CUDA Host Allocated (cudaHostAlloc)\n");
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

    /* Allocate mapped CPU memory. */
    npoint = atoi(argv[3]);
    nvert = atoi(argv[5]);
    pbytes = npoint*sizeof(float);
    vbytes = nvert*sizeof(float);
    cbytes = npoint*sizeof(char);

    if (bPinGenericMemory) {
#if CUDART_VERSION >= 4000
        gettimeofday(&start, NULL);
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
        c = (char *) ALIGN_UP(c_UA, MEMORY_ALIGNMENT);

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

    /*Points*/
    gettimeofday(&start, NULL);
    if (!getPoints(argv[2], npoint, &px, &py)) {
        //TODO clean memory
        printf("Failed to get Points!!!\n");
        return -1;
    }
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("Populate Points took %llu ms\n", t);

    /*Vertex of the Polygon*/
    gettimeofday(&start, NULL);
    if (!getPoints(argv[4], nvert, &vx, &vy)) {
        //TODO clean memory
        printf("Failed to get Polygon!!!\n");
        return -1;
    }
    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("Populate Polygon took %llu ms\n", t);

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
    printf("> pnpoly_cnGPU kernel will check which points are in the Polygon using mapped CPU memory...\n");
    //dim3 block(256);
    dim3 block(BLOCK_SIZE);
    dim3 grid((unsigned int)ceil(npoint/(float)block.x));
    //vectorAddGPU<<<grid, block>>>(d_a, d_b, d_c, nelem);
    gettimeofday(&start, NULL);
    
    //pnpoly_cnGPU<<<grid, block>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);
    //size_t sh_size = 2*607*sizeof(float);
    //pnpoly_cnGPU<<<grid, block,sh_size>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);

    cudaEventCreate(&cstart);
    cudaEventCreate(&cstop);
    cudaEventRecord(cstart);
    pnpoly_cnGPU1<<<grid, block>>>(d_px, d_py, d_vx, d_vy, d_c, npoint, nvert);
    cudaEventRecord(cstop);

    checkCudaErrors(cudaDeviceSynchronize());
    getLastCudaError("pnpoly_cnGPU() execution failed");

    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;

    cudaEventSynchronize(cstop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, cstart, cstop);

    printf("PnPoly took %llu ms and %f msecs CUDA\n", t, milliseconds);


    /* Output results */
    printf("> Checking the results from vectorAddGPU() ...\n");
    outputResult(argv[6], c, npoint, px, py);

    /* Memory clean up */
    printf("> Releasing CPU memory...\n");

    if (bPinGenericMemory) {
#if CUDART_VERSION >= 4000
        checkCudaErrors(cudaHostUnregister(px));
        checkCudaErrors(cudaHostUnregister(py));
        checkCudaErrors(cudaHostUnregister(vx));
        checkCudaErrors(cudaHostUnregister(vy));
        checkCudaErrors(cudaHostUnregister(c));
        free(px_UA);
        free(py_UA);
        free(vx_UA);
        free(vy_UA);
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
    cudaDeviceReset();
}
