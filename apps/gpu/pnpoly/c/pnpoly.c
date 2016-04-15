#include <stdio.h>
#include <stdlib.h>
#include <time.h>


int pnpoly_cn(int **res, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0;
    int *cs = NULL;
    cs = malloc(sizeof(int)*npoint);

    for (i = 0; i < npoint; i++) {
        int j, k, c = 0;
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

int pnpoly_wn(int **res, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0, j =0;
    int *cs = NULL;
    cs = malloc(sizeof(int)*npoint);

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

    *res=cs;
    return 0;
}

int pnpoly_wnLeft(int **res, int nvert, double *vx, double *vy, int npoint, double *px, double *py)
{
    int i = 0, j =0;
    int *cs = NULL;
    cs = malloc(sizeof(int)*npoint);

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

    *res=cs;
    return 0;
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

int outputResult(char *filename, int *cs, int npoint, double *px, double *py) {
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
    double *px, *py, *vx, *vy;
    int nvert, npoint;
    int *cs = NULL;
    struct timeval stop, start;
    unsigned long long t;
        
    if (argc != 7) {
        printf("Wrong number of arguments:\n./pnpoly <func [0 for cn | 1 for wn | 2 for wnLeft]> <polygon_filename> <num_vertex> <points_filename> <num_points> <out_filename>\n");
        return 0;
    }

    /*Points*/
    if (!(npoint = getPoints(argv[2], atoi(argv[3]), &px, &py))) {
        printf("Failed to get Points!!!");
        return -1;
    }

    /*Vertex of the Polygon*/
    if (!(nvert = getPoints(argv[4], atoi(argv[5]), &vx, &vy))) {
        printf("Failed to get Points!!!");
        return -1;
    }

    gettimeofday(&start, NULL);
    switch(atoi(argv[1])) {
        case 0:
            pnpoly_cn(&cs, nvert, vx, vy, npoint, px, py);
            break;
        case 1:
            pnpoly_wn(&cs, nvert, vx, vy, npoint, px, py);
            break;
        case 2:
            pnpoly_wnLeft(&cs, nvert, vx, vy, npoint, px, py);
            break;
        default:
            printf("Wrong number of arguments:\n./pnpoly <func [0 for cn | 1 for wn | 2 for wnLeft]> <polygon_filename> <num_vertex> <points_filename> <num_points> <out_filename>\n");
            return 0;
    }

    gettimeofday(&stop, NULL);
    t = 1000 * (stop.tv_sec - start.tv_sec) + (stop.tv_usec - start.tv_usec) / 1000;
    printf("took %llu ms\n", t);

    outputResult(argv[6], cs, npoint, px, py);

    free(cs);
    free(px);
    free(py);
    free(vx);
    free(vy);
}
