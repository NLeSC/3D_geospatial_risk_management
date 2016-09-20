#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <omp.h>

int pnpoly_cn(char **res, int nthreads, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0;
    int j, k, c = 0;
    char *cs = NULL;
    cs = malloc(sizeof(char)*npoint);
    omp_set_dynamic(0);     // Explicitly disable dynamic teams
    omp_set_num_threads(nthreads);
    #pragma omp parallel for private(j,k,c)
    for (i = 0; i < npoint; i++) {
        c = 0;
        for (j = 0, k = nvert-1; j < nvert; k = j++) {
            if ( ((vy[j]>py[i]) != (vy[k]>py[i])) &&
                    (px[i] < (vx[k]-vx[j]) * (py[i]-vy[j]) / (vy[k]-vy[j]) + vx[j]) )
                c = !c;
        }
        cs[i] = c & 1;
    }

    *res=cs;
    return 0;
}

double isLeft( double P0x, double P0y, double P1x, double P1y, double P2x, double P2y)
{
    return ( (P1x - P0x) * (P2y - P0y) - (P2x -  P0x) * (P1y - P0y) );
}

int pnpoly_wn(char **res, int nthreads, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0, j =0, wn = 0;
    char *cs = NULL;
    cs = malloc(sizeof(char)*npoint);

    //omp_set_dynamic(0);     // Explicitly disable dynamic teams
    //omp_set_num_threads(nthreads);

    #pragma omp parallel for private(j,wn)
    for (i = 0; i < npoint; i++) {
        wn = 0;
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

    *res=cs;
    return 0;
}

int pnpoly_wnLeft(char **res, int nthreads, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0, j =0, wn = 0;
    char *cs = NULL;
    cs = malloc(sizeof(char)*npoint);

    //omp_set_dynamic(0);     // Explicitly disable dynamic teams
    //omp_set_num_threads(nthreads);
    #pragma omp parallel for private(j, wn)
    for (i = 0; i < npoint; i++) {
        wn = 0;
        for (j = 0; j < nvert-1; j++) {
            wn += (vy[j] <= py[i] && vy[j+1] > py[i] && (( (vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j]) ) > 0))*1 || (vy[j] > py[i] && vy[j+1] <= py[i] && ( ((vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j])) < 0))*-1 ; 
        }
        cs[i] = wn & 1;
    }

    *res=cs;
    return 0;
}

int pnpoly_wnLeftA(char **res, int nthreads, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0, j =0, wn = 0;
    char *cs = NULL;
    cs = malloc(sizeof(char)*npoint);

    omp_set_dynamic(0);     // Explicitly disable dynamic teams
    omp_set_num_threads(nthreads);
    #pragma omp parallel for private(j,wn)
    for (i = 0; i < npoint; i++) {
        wn = 0;
        for (j = 0; j < nvert-1; j++) {
            if (vy[j] <= py[i]) {
                if (vy[j+1] > py[i] && (( (vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j]) ) > 0))
                        ++wn;
            }
            else {
                if (vy[j+1]  <= py[i] && (( (vx[j+1] - vx[j]) * (py[i] - vy[j]) - (px[i] -  vx[j]) * (vy[j+1] - vy[j]) ) < 0))
                        --wn;
            }
        }
        cs[i] = wn & 1;
    }

    *res=cs;
    return 0;
}

int getPointsFile(char* filename, int npoint, double **p) {
    FILE *fp = NULL;
    int points = 0, i = 0;
    double *pt;

    fp = fopen(filename, "rb");

    if (fp == NULL)
        exit(EXIT_FAILURE);

    pt = malloc(sizeof(double)*npoint);
    for (i = 0; i < npoint; i++) {
        points += fread(&pt[i], sizeof(double), 1, fp);
    }

    fclose(fp);

    printf("npoints %d points %d \n", npoint, points);
    if (npoint != points)
        points = 0;

    *p = pt;

    return points;
}

int getPoints(char* filename, int npoint, double **px, double **py) {
    FILE *fp = NULL;
    char * line = NULL;
    size_t len = 0;
    ssize_t read = 0;
    int points = 0;
    double *ptx, *pty;

    fp = fopen(filename, "r");

    if (fp == NULL)
        exit(EXIT_FAILURE);

    ptx = malloc(sizeof(double)*npoint);
    pty = malloc(sizeof(double)*npoint);

    while ((read = getline(&line, &len, fp)) != -1) {
        line[read-1]='\0';
        sscanf(line, "%lf %lf", &ptx[points], &pty[points]);
        points++;
    }

    fclose(fp);
    if (line)
        free(line);
    if (npoint != points)
        points = 0;
    *px = ptx;
    *py = pty;

    return points;
}

int outputResult(char *filename, char *cs, int npoint, double *px, double *py) {
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

int main(int argc, char* argv[]){
    double *px = NULL, *py = NULL, *vx = NULL, *vy = NULL;
    int nvert, npoint, num_times, k = 0;
    char *cs = NULL;
    struct timeval stop, start;
    unsigned long long t;
        
    if (argc != 10) {
        printf("Wrong number of arguments:\n./pnpoly <num_times> <func [0 for cn | 1 for wn | 2 for wnLeft]> <num_threads> <X_filename> <Y_filename> <num_points> <polygon_filename> <num_vertex> <out_filename>\n");
        return 0;
    }

    /*Number of Times*/
    num_times = atoi(argv[1]);

    /*Points*/
    if (!(npoint = getPointsFile(argv[4], atoi(argv[6]), &px))) {
        printf("Failed to get Points for X!!!\n");
        goto out;
    }

    if (!(npoint = getPointsFile(argv[5], atoi(argv[6]), &py))) {
        printf("Failed to get Points for Y!!!\n");
        goto out;
    }

    /*Vertex of the Polygon*/
    if (!(nvert = getPoints(argv[7], atoi(argv[8]), &vx, &vy))) {
        printf("Failed to get Points!!!\n");
        goto out;
    }

    for (k = 0; k < num_times; k++) {
        gettimeofday(&start, NULL);
        switch(atoi(argv[2])) {
            case 0:
                pnpoly_cn(&cs, atoi(argv[3]), nvert, vx, vy, npoint, px, py);
                break;
            case 1:
                pnpoly_wn(&cs, atoi(argv[3]), nvert, vx, vy, npoint, px, py);
                break;
            case 2:
                pnpoly_wnLeft(&cs, atoi(argv[3]), nvert, vx, vy, npoint, px, py);
                break;
            default:
                printf("Incorrect argument:\n./pnpoly <num_times> <func [0 for cn | 1 for wn | 2 for wnLeft]> <num_threads> <X_filename> <Y_filename> <num_points> <polygon_filename> <num_vertex> <out_filename>\n");
                goto out;
        }

        gettimeofday(&stop, NULL);
        t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
        printf("took %llu ms\n", t);
    }

    outputResult(argv[9], cs, npoint, px, py);

out:
    if (cs)
        free(cs);
    if (px)
        free(px);
    if (py)
        free(py);
    if (vx)
        free(vx);
    if (vy)
        free(vy);
}
