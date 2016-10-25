#include <sys/time.h>

#ifndef MAX 
#define MAX(a,b) (a > b ? a : b) 
#endif

#define THREADS_PER_BLOCK 512
#define BLOCK_SIZE 256

#define cudaDeviceScheduleBlockingSync   0x04 

/*
 * Macro to aligned up to the memory size in question
 */
#define MEMORY_ALIGNMENT  4096
#define ALIGN_UP(x,size) ( ((size_t)x+(size-1))&(~(size-1)) )

#define G_PNPOLY_DEBUG 0

//extern int GPU_SETUP;
int pnpoly_GPU(signed char **mc, int nvert, int npoint, float *mpx, float *mpy, float *mvx, float *mvy);
int setup_GPU();
void reset_GPU();
