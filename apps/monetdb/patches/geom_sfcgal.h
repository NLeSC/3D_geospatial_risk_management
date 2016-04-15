#include "sfcgal.h"

/* Convert SFCGAL structure to lwgeom PostGIS */
GEOSGeom*
sfcgal2geos(const sfcgal_geometry_t* geom, int force3D, int SRID);

/* Convert geom to SFCGAL structure */
str 
geos2sfcgal(sfcgal_geometry_t **res, GEOSGeom geosGeometry);
