#include "geom.h"	/* strlen */
#include <math.h>	/* strlen */
#include <stdio.h>	/* strlen */
#include <string.h>	/* strlen */
#include <assert.h>

#define OUT_MAX_DOUBLE_PRECISION 15
#define OUT_MAX_DOUBLE 1E15
#define OUT_SHOW_DIGS_DOUBLE 20
#define OUT_MAX_DOUBLE_PRECISION 15
#define OUT_MAX_DIGS_DOUBLE (OUT_SHOW_DIGS_DOUBLE + 2) /* +2 mean add dot and sign */

typedef struct {
	double xmin; 
	double ymin; 
	double zmin; 
	double xmax; 
	double ymax; 
	double zmax; 
} box3D;

char* geom_to_geojson(GEOSGeom geom, char *srs, int precision, int has_bbox);
