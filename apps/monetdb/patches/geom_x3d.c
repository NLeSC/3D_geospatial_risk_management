#include "geom_export.h"

#define LW_X3D_FLIP_XY     (1<<0)
#define LW_X3D_USE_GEOCOORDS     (1<<1)
#define X3D_USE_GEOCOORDS(x) ((x) & LW_X3D_USE_GEOCOORDS)

static size_t x3d_3_point_size(GEOSGeom point, int precision);
static char *x3d_3_point(GEOSGeom point, int precision, int opts);
static size_t x3d_3_line_size(GEOSGeom line, int precision, int opts, const char *defid);
static char *x3d_3_line(GEOSGeom line, int precision, int opts, const char *defid);
static size_t x3d_3_poly_size(GEOSGeom poly, int precision, const char *defid);
static size_t x3d_3_triangle_size(GEOSGeom triangle, int precision, const char *defid);
static char *x3d_3_triangle(GEOSGeom triangle, int precision, int opts, const char *defid);
static size_t x3d_3_multi_size(GEOSGeom col, int precisioSn, int opts, const char *defid);
static char *x3d_3_multi(GEOSGeom col, int precision, int opts, const char *defid);
static char *x3d_3_psurface(GEOSGeom psur, int precision, int opts, const char *defid);
static char *x3d_3_tin(GEOSGeom tin, int precision, int opts, const char *defid);
static size_t x3d_3_collection_size(GEOSGeom col, int precision, int opts, const char *defid);
static char *x3d_3_collection(GEOSGeom col, int precision, int opts, const char *defid);
static size_t geom_toX3D3(GEOSGeom geom, char *buf, int precision, int opts, int is_closed);

static size_t geom_X3Dsize(GEOSGeom geom, int precision);
static void trim_trailing_zeros(char *str);
static void GEOSGeomGetZ(GEOSGeom geom, double *z);

/*
 * VERSION X3D 3.0.2 http://www.web3d.org/specifications/x3d-3.0.dtd
 */


/* takes a GEOMETRY and returns an X3D representation */
extern char *
geom_to_x3d_3(GEOSGeom geom, int precision, int opts, const char *defid)
{
	int type = GEOSGeomTypeId(geom)+1;

	switch (type)
	{
	case wkbPoint_mdb:
		return x3d_3_point(geom, precision, opts);

	case wkbLineString_mdb:
		return x3d_3_line(geom, precision, opts, defid);

	case wkbPolygon_mdb:
	{
		/** We might change this later, but putting a polygon in an indexed face set
		* seems like the simplest way to go so treat just like a mulitpolygon
		*/
		GEOSGeom tmp = NULL; //TODO: = geom_as_multi(geom);
		char *ret = x3d_3_multi(tmp, precision, opts, defid);
		//TODO: lwcollection_free(tmp);
		return ret;
	}

	case wkbTriangle_mdb:
		return x3d_3_triangle(geom, precision, opts, defid);

	case wkbMultiPoint_mdb:
	case wkbMultiLineString_mdb:
	case wkbMultiPolygon_mdb:
		return x3d_3_multi(geom, precision, opts, defid);

	case wkbPolyehdralSurface_mdb:
		return x3d_3_psurface(geom, precision, opts, defid);

	case wkbTin_mdb:
		return x3d_3_tin(geom, precision, opts, defid);

	case wkbGeometryCollection_mdb:
		return x3d_3_collection(geom, precision, opts, defid);

	default:
		//TODO: Fix throw(MAL, "geom_to_geojson", "Unknown geometry type");
		return NULL;
	}
}

static size_t
x3d_3_point_size(GEOSGeom point, int precision)
{
	int size;
	size = geom_X3Dsize(point, precision);
	return size;
}

static size_t
x3d_3_point_buf(GEOSGeom point, char *output, int precision, int opts)
{
	char *ptr = output;
	ptr += geom_toX3D3(point, ptr, precision, opts, 0);
	return (ptr-output);
}

static char *
x3d_3_point(GEOSGeom point, int precision, int opts)
{
	char *output;
	int size;

	size = x3d_3_point_size(point, precision);
	output = GDKmalloc(size);
	x3d_3_point_buf(point, output, precision, opts);
	return output;
}


static size_t
x3d_3_line_size(GEOSGeom line, int precision, int opts, const char *defid)
{
	int size;
	size_t defidlen = strlen(defid);

	size = geom_X3Dsize(line, precision)*2;
	
	if ( X3D_USE_GEOCOORDS(opts) ) {
			size += (
	            sizeof("<LineSet vertexCount=''><GeoCoordinate geoSystem='\"GD\" \"WE\" \"longitude_first\"' point='' /></LineSet>")  + defidlen
	        ) * 2;
	}
	else {
		size += (
		            sizeof("<LineSet vertexCount=''><Coordinate point='' /></LineSet>")  + defidlen
		        ) * 2;
	}

	return size;
}

static size_t
x3d_3_line_buf(GEOSGeom line, char *output, int precision, int opts, const char *defid)
{
	char *ptr=output;
	const GEOSCoordSequence* gcs_new = GEOSGeom_getCoordSeq(line);
	uint32_t npoints;
	GEOSCoordSeq_getSize(gcs_new, &npoints);

	ptr += sprintf(ptr, "<LineSet %s vertexCount='%d'>", defid, npoints);

	if ( X3D_USE_GEOCOORDS(opts) ) ptr += sprintf(ptr, "<GeoCoordinate geoSystem='\"GD\" \"WE\" \"%s\"' point='", ( (opts & LW_X3D_FLIP_XY) ? "latitude_first" : "longitude_first") );
	else
		ptr += sprintf(ptr, "<Coordinate point='");
	ptr += geom_toX3D3(line, ptr, precision, opts, GEOSisClosed(line));

	ptr += sprintf(ptr, "' />");

	ptr += sprintf(ptr, "</LineSet>");
	return (ptr-output);
}

static size_t
x3d_3_line_coords(GEOSGeom line, char *output, int precision, int opts)
{
	char *ptr=output;
	ptr += geom_toX3D3(line, ptr, precision, opts, GEOSisClosed(line));
	return (ptr-output);
}

static size_t
x3d_3_mline_coordindex(GEOSGeom mgeom, char *output)
{
	char *ptr=output;
	int i, j, si;
	GEOSGeom geom;
	int ngeoms = GEOSGetNumGeometries(mgeom);

	j = 0;
	for (i=0; i < ngeoms; i++)
	{
		const GEOSCoordSequence* gcs_new;
		uint32_t k, npoints;
		geom = (GEOSGeom ) GEOSGetGeometryN(mgeom, i);
		gcs_new = GEOSGeom_getCoordSeq(geom);
		GEOSCoordSeq_getSize(gcs_new, &npoints);
		si = j;  /* start index of first point of linestring */
		for (k=0; k < npoints ; k++)
		{
			if (k)
			{
				ptr += sprintf(ptr, " ");
			}
			/** if the linestring is closed, we put the start point index
			*   for the last vertex to denote use first point
			*    and don't increment the index **/
			if (!GEOSisClosed(geom) || k < (npoints -1) )
			{
				ptr += sprintf(ptr, "%d", j);
				j += 1;
			}
			else
			{
				ptr += sprintf(ptr,"%d", si);
			}
		}
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " -1 "); /* separator for each linestring */
		}
	}
	return (ptr-output);
}

/* Calculate the coordIndex property of the IndexedLineSet for a multipolygon
    This is not ideal -- would be really nice to just share this function with psurf,
    but I'm not smart enough to do that yet*/
static size_t
x3d_3_mpoly_coordindex(GEOSGeom psur, char *output)
{
	char *ptr=output;
	GEOSGeom patch;
	int i, j, l;
	int ngeoms = GEOSGetNumGeometries(psur);
	j = 0;
	for (i=0; i<ngeoms; i++)
	{
		int nrings;
		patch = (GEOSGeom ) GEOSGetGeometryN(psur, i);
		nrings = GEOSGetNumInteriorRings(patch);
		for (l=0; l < nrings; l++)
		{
			GEOSGeom ring = *(GEOSGeom*)GEOSGetInteriorRingN(patch, l);
			const GEOSCoordSequence* gcs_new = GEOSGeom_getCoordSeq(ring);
			uint32_t k, npoints;
			GEOSCoordSeq_getSize(gcs_new, &npoints);

			for (k=0; k < npoints ; k++)
			{
				if (k)
				{
					ptr += sprintf(ptr, " ");
				}
				ptr += sprintf(ptr, "%d", (j + k));
			}
			j += k;
			if (l < (nrings - 1) )
			{
				ptr += sprintf(ptr, " -1 "); /* separator for each inner ring. Ideally we should probably triangulate and cut around as others do */
			}
		}
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " -1 "); /* separator for each subgeom */
		}
	}
	return (ptr-output);
}

/** Return the linestring as an X3D LineSet */
static char *
x3d_3_line(GEOSGeom line, int precision, int opts, const char *defid)
{
	char *output;
	int size;

	size = sizeof("<LineSet><CoordIndex ='' /></LineSet>") + x3d_3_line_size(line, precision, opts, defid);
	output = GDKmalloc(size);
	x3d_3_line_buf(line, output, precision, opts, defid);
	return output;
}

/** Compute the string space needed for the IndexedFaceSet representation of the polygon **/
static size_t
x3d_3_poly_size(GEOSGeom poly,  int precision, const char *defid)
{
	size_t size;
	size_t defidlen = strlen(defid);
	int i, nrings = GEOSGetNumInteriorRings(poly);

	size = ( sizeof("<IndexedFaceSet></IndexedFaceSet>") + (defidlen*3) ) * 2 + 6 * (nrings - 1);

	for (i=0; i<nrings; i++)
		size += geom_X3Dsize(*(GEOSGeom*)GEOSGetInteriorRingN(poly, i), precision);

	return size;
}

/** Compute the X3D coordinates of the polygon **/
static size_t
x3d_3_poly_buf(GEOSGeom poly, char *output, int precision, int opts)
{
	int i, nrings = GEOSGetNumInteriorRings(poly);
	char *ptr=output;

	ptr += geom_toX3D3(*(GEOSGeom*)GEOSGetInteriorRingN(poly, 0), ptr, precision, opts, 1);
	for (i=1; i<nrings; i++)
	{
		ptr += sprintf(ptr, " "); /* inner ring points start */
		ptr += geom_toX3D3(*(GEOSGeom*)GEOSGetInteriorRingN(poly, i), ptr, precision, opts,1);
	}
	return (ptr-output);
}

static size_t
x3d_3_triangle_size(GEOSGeom triangle, int precision, const char *defid)
{
	size_t size;
	size_t defidlen = strlen(defid);

	/** 6 for the 3 sides and space to separate each side **/
	size = sizeof("<IndexedTriangleSet index=''></IndexedTriangleSet>") + defidlen + 6;
	size += geom_X3Dsize(triangle, precision);

	return size;
}

static size_t
x3d_3_triangle_buf(GEOSGeom triangle, char *output, int precision, int opts)
{
	char *ptr=output;
	ptr += geom_toX3D3(triangle, ptr, precision, opts, 1);

	return (ptr-output);
}

static char *
x3d_3_triangle(GEOSGeom triangle, int precision, int opts, const char *defid)
{
	char *output;
	int size;

	size = x3d_3_triangle_size(triangle, precision, defid);
	output = GDKmalloc(size);
	x3d_3_triangle_buf(triangle, output, precision, opts);
	return output;
}


/**
 * Compute max size required for X3D version of this
 * inspected geometry. Will recurse when needed.
 * Don't call this with single-geoms inspected.
 */
static size_t
x3d_3_multi_size(GEOSGeom col, int precision, int opts, const char *defid)
{
	int i, ngeoms = GEOSGetNumGeometries(col);
	size_t size;
	size_t defidlen = strlen(defid);
	GEOSGeom subgeom;

	/* the longest possible multi version needs to hold DEF=defid and coordinate breakout */
	if ( X3D_USE_GEOCOORDS(opts) )
		size = sizeof("<PointSet><GeoCoordinate geoSystem='\"GD\" \"WE\" \"longitude_first\"' point='' /></PointSet>");
	else
		size = sizeof("<PointSet><Coordinate point='' /></PointSet>") + defidlen;
	
	for (i=0; i<ngeoms; i++)
	{
	    int type;
		subgeom = (GEOSGeom) GEOSGetGeometryN(col, i);
	    type = GEOSGeomTypeId(subgeom)+1;
		if (type == wkbPoint_mdb)
		{
			size += x3d_3_point_size(subgeom, precision);
		}
		else if (type == wkbLineString_mdb)
		{
			size += x3d_3_line_size(subgeom, precision, opts, defid);
		}
		else if (type == wkbPolygon_mdb)
		{
			size += x3d_3_poly_size(subgeom, precision, defid);
		}
	}

	return size;
}

/*
 * Don't call this with single-geoms inspected!
 */
static size_t
x3d_3_multi_buf(GEOSGeom col, char *output, int precision, int opts, const char *defid)
{
	char *ptr, *x3dtype;
	int i;
	int ngeoms;
	int dimension= GEOS_getWKBOutputDims(col);
	int type = GEOSGeomTypeId(col)+1;

	GEOSGeom subgeom;
	ptr = output;
	x3dtype="";


	switch (type)
	{
        case wkbMultiPoint_mdb:
            x3dtype = "PointSet";
            if ( dimension == 2 ){ /** Use Polypoint2D instead **/
                x3dtype = "Polypoint2D";   
                ptr += sprintf(ptr, "<%s %s point='", x3dtype, defid);
            }
            else {
                ptr += sprintf(ptr, "<%s %s>", x3dtype, defid);
            }
            break;
        case wkbMultiLineString_mdb:
            x3dtype = "IndexedLineSet";
            ptr += sprintf(ptr, "<%s %s coordIndex='", x3dtype, defid);
            ptr += x3d_3_mline_coordindex((GEOSGeom )col, ptr);
            ptr += sprintf(ptr, "'>");
            break;
        case wkbMultiPolygon_mdb:
            x3dtype = "IndexedFaceSet";
            ptr += sprintf(ptr, "<%s %s convex='false' coordIndex='", x3dtype, defid);
            ptr += x3d_3_mpoly_coordindex((GEOSGeom )col, ptr);
            ptr += sprintf(ptr, "'>");
            break;
        default:
	        //TODO: Fix throw(MAL, "geom_to_geojson", "Unknown geometry type");
            return 0;
    }
    if (dimension == 3){
		if ( X3D_USE_GEOCOORDS(opts) ) 
			ptr += sprintf(ptr, "<GeoCoordinate geoSystem='\"GD\" \"WE\" \"%s\"' point='", ((opts & LW_X3D_FLIP_XY) ? "latitude_first" : "longitude_first") );
		else
        	ptr += sprintf(ptr, "<Coordinate point='");
    }
	ngeoms = GEOSGetNumGeometries(col);
	for (i=0; i<ngeoms; i++)
	{
	    int type;
		subgeom =  (GEOSGeom ) GEOSGetGeometryN(col, i);
	    type = GEOSGeomTypeId(subgeom)+1;
		if (type == wkbPoint_mdb)
		{
			ptr += x3d_3_point_buf(subgeom, ptr, precision, opts);
			ptr += sprintf(ptr, " ");
		}
		else if (type == wkbLineString_mdb)
		{
			ptr += x3d_3_line_coords(subgeom, ptr, precision, opts);
			ptr += sprintf(ptr, " ");
		}
		else if (type == wkbPolygon_mdb)
		{
			ptr += x3d_3_poly_buf(subgeom, ptr, precision, opts);
			ptr += sprintf(ptr, " ");
		}
	}

	/* Close outmost tag */
	if (dimension == 3){
	    ptr += sprintf(ptr, "' /></%s>", x3dtype);
	}
	else { ptr += sprintf(ptr, "' />"); }    
	return (ptr-output);
}

/*
 * Don't call this with single-geoms inspected!
 */
static char *
x3d_3_multi(GEOSGeom col, int precision, int opts, const char *defid)
{
	char *x3d;
	size_t size;

	size = x3d_3_multi_size(col, precision, opts, defid);
	x3d = GDKmalloc(size);
	x3d_3_multi_buf(col, x3d, precision, opts, defid);
	return x3d;
}


static size_t
x3d_3_psurface_size(GEOSGeom psur, int precision, int opts, const char *defid)
{
	int i, ngeoms = GEOSGetNumGeometries(psur);
	size_t size;
	size_t defidlen = strlen(defid);

	if ( X3D_USE_GEOCOORDS(opts) ) size = sizeof("<IndexedFaceSet convex='false' coordIndex=''><GeoCoordinate geoSystem='\"GD\" \"WE\" \"longitude_first\"' point='' />") + defidlen;
	else size = sizeof("<IndexedFaceSet convex='false' coordIndex=''><Coordinate point='' />") + defidlen;
	

	for (i=0; i<ngeoms; i++)
	{
		size += x3d_3_poly_size((GEOSGeom) GEOSGetGeometryN(psur, i), precision, defid)*5; /** need to make space for coordIndex values too including -1 separating each poly**/
	}

	return size;
}


/*
 * Don't call this with single-geoms inspected!
 */
static size_t
x3d_3_psurface_buf(GEOSGeom psur, char *output, int precision, int opts, const char *defid)
{
	char *ptr;
	int i, ngeoms = GEOSGetNumGeometries(psur);
	int j;
	GEOSGeom patch;

	ptr = output;

	/* Open outmost tag */
	ptr += sprintf(ptr, "<IndexedFaceSet convex='false' %s coordIndex='",defid);

	j = 0;
	for (i=0; i<ngeoms; i++)
	{
	    uint32_t k, npoints;
		GEOSGeom ring;
		const GEOSCoordSequence* gcs_new;
		patch = (GEOSGeom ) GEOSGetGeometryN(psur, i);
		ring =*(GEOSGeom*)GEOSGetInteriorRingN(patch, 0);

		gcs_new = GEOSGeom_getCoordSeq(ring);
		GEOSCoordSeq_getSize(gcs_new, &npoints);
		
		for (k=0; k < npoints ; k++)
		{
			if (k)
			{
				ptr += sprintf(ptr, " ");
			}
			ptr += sprintf(ptr, "%d", (j + k));
		}
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " -1 "); /* separator for each subgeom */
		}
		j += k;
	}

	if ( X3D_USE_GEOCOORDS(opts) ) 
		ptr += sprintf(ptr, "'><GeoCoordinate geoSystem='\"GD\" \"WE\" \"%s\"' point='", ( (opts & LW_X3D_FLIP_XY) ? "latitude_first" : "longitude_first") );
	else ptr += sprintf(ptr, "'><Coordinate point='");

	for (i=0; i<ngeoms; i++)
	{
		ptr += x3d_3_poly_buf((GEOSGeom ) GEOSGetGeometryN(psur, i), ptr, precision, opts);
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " "); /* only add a trailing space if its not the last polygon in the set */
		}
	}

	/* Close outmost tag */
	ptr += sprintf(ptr, "' /></IndexedFaceSet>");

	return (ptr-output);
}

/*
 * Don't call this with single-geoms inspected!
 */
static char *
x3d_3_psurface(GEOSGeom psur, int precision, int opts, const char *defid)
{
	char *x3d;
	size_t size;

	size = x3d_3_psurface_size(psur, precision, opts, defid);
	x3d = GDKmalloc(size);
	x3d_3_psurface_buf(psur, x3d, precision, opts, defid);
	return x3d;
}


static size_t
x3d_3_tin_size(GEOSGeom tin, int precision, const char *defid)
{
	int i, ngeoms = GEOSGetNumGeometries(tin);
	size_t size;
	size_t defidlen = strlen(defid);

	/** Need to make space for size of additional attributes,
	** the coordIndex has a value for each edge for each triangle plus a space to separate so we need at least that much extra room ***/
	size = sizeof("<IndexedTriangleSet coordIndex=''></IndexedTriangleSet>") + defidlen + ngeoms*12;

	for (i=0; i<ngeoms; i++)
	{
		size += (x3d_3_triangle_size((GEOSGeom ) GEOSGetGeometryN(tin, i), precision, defid) * 20); /** 3 is to make space for coordIndex **/
	}

	return size;
}


/*
 * Don't call this with single-geoms inspected!
 */
static size_t
x3d_3_tin_buf(GEOSGeom tin, char *output, int precision, int opts, const char *defid)
{
	char *ptr;
	int i, ngeoms = GEOSGetNumGeometries(tin);
	int k;
	/* int dimension=2; */

	ptr = output;

	ptr += sprintf(ptr, "<IndexedTriangleSet %s index='",defid);
	k = 0;
	/** Fill in triangle index **/
	for (i=0; i<ngeoms; i++)
	{
		ptr += sprintf(ptr, "%d %d %d", k, (k+1), (k+2));
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " ");
		}
		k += 3;
	}

	if ( X3D_USE_GEOCOORDS(opts) ) ptr += sprintf(ptr, "'><GeoCoordinate geoSystem='\"GD\" \"WE\" \"%s\"' point='", ( (opts & LW_X3D_FLIP_XY) ? "latitude_first" : "longitude_first") );
	else ptr += sprintf(ptr, "'><Coordinate point='");
	
	for (i=0; i<ngeoms; i++)
	{
		ptr += x3d_3_triangle_buf((GEOSGeom ) GEOSGetGeometryN(tin, i), ptr, precision,
		                           opts);
		if (i < (ngeoms - 1) )
		{
			ptr += sprintf(ptr, " ");
		}
	}

	/* Close outmost tag */

	ptr += sprintf(ptr, "'/></IndexedTriangleSet>");

	return (ptr-output);
}

/*
 * Don't call this with single-geoms inspected!
 */
static char *
x3d_3_tin(GEOSGeom tin, int precision, int opts, const char *defid)
{
	char *x3d;
	size_t size;

	size = x3d_3_tin_size(tin, precision, defid);
	x3d = GDKmalloc(size);
	x3d_3_tin_buf(tin, x3d, precision, opts, defid);
	return x3d;
}

static size_t
x3d_3_collection_size(GEOSGeom col, int precision, int opts, const char *defid)
{
	int i, ngeoms = GEOSGetNumGeometries(col);
	size_t size;
	size_t defidlen = strlen(defid);
	int type = GEOSGeomTypeId(col)+1;

	size = defidlen*2;
	for (i=0; i<ngeoms; i++)
	{
		GEOSGeom subgeom = (GEOSGeom) GEOSGetGeometryN(col, i);
		size += ( sizeof("<Shape />") + defidlen ) * 2; /** for collections we need to wrap each in a shape tag to make valid **/
        switch (type) {
            case ( wkbPoint_mdb ):
                size += x3d_3_point_size(subgeom, precision);
                break;
            case ( wkbLineString_mdb ):
                size += x3d_3_line_size(subgeom, precision, opts, defid);
                break;
            case ( wkbPolygon_mdb ):
                size += x3d_3_poly_size(subgeom, precision, defid);
                break;
            case ( wkbTin_mdb ):
                size += x3d_3_tin_size(subgeom, precision, defid);
                break;
            case ( wkbPolyehdralSurface_mdb ):
                size += x3d_3_psurface_size(subgeom, precision, opts, defid);
                break;
            case ( wkbGeometryCollection_mdb ):
            case ( wkbMultiPolygon_mdb ):
                size += x3d_3_multi_size(subgeom, precision, opts, defid);
                break;
            default:
                //TODO: Fix throw(MAL, "geom_to_geojson", "Unknown geometry type");
                size = 0;
        }
	}

	return size;
}

static size_t
x3d_3_collection_buf(GEOSGeom col, char *output, int precision, int opts, const char *defid)
{
	char *ptr;
	int i, ngeoms = GEOSGetNumGeometries(col);
	GEOSGeom subgeom;
	int type = GEOSGeomTypeId(col)+1;

	ptr = output;

	/* Open outmost tag */
	/** @TODO: decide if we need outtermost tags, this one was just a copy from gml so is wrong **/
#ifdef PGIS_X3D_OUTERMOST_TAGS
	if ( srs )
	{
		ptr += sprintf(ptr, "<%sMultiGeometry srsName=\"%s\">", defid, srs);
	}
	else
	{
		ptr += sprintf(ptr, "<%sMultiGeometry>", defid);
	}
#endif

	for (i=0; i<ngeoms; i++)
	{
		subgeom = (GEOSGeom ) GEOSGetGeometryN(col, i);
		ptr += sprintf(ptr, "<Shape%s>", defid);
        switch (type) {
            case ( wkbPoint_mdb ):
                ptr += x3d_3_point_buf(subgeom, ptr, precision, opts);
                break;
            case ( wkbLineString_mdb ):
                ptr += x3d_3_line_buf(subgeom, ptr, precision, opts, defid);
                break;
            case ( wkbPolygon_mdb ):
                ptr += x3d_3_poly_buf(subgeom, ptr, precision, opts);
                break;
            case ( wkbTin_mdb ):
                ptr += x3d_3_tin_buf(subgeom, ptr, precision, opts,  defid);
                break;
            case ( wkbPolyehdralSurface_mdb ):
                ptr += x3d_3_psurface_buf(subgeom, ptr, precision, opts,  defid);
                break;
            case ( wkbGeometryCollection_mdb ):
                ptr += x3d_3_collection_buf(subgeom, ptr, precision, opts, defid);
                break;
            case wkbMultiPolygon_mdb:
                ptr += x3d_3_multi_buf(subgeom, ptr, precision, opts, defid);
                break;
            default:
		        //TODO: Fix throw(MAL, "geom_to_geojson", "Unknown geometry type");
			    ptr += printf(ptr, "");
        }

		ptr += printf(ptr, "</Shape>");
	}

	/* Close outmost tag */
#ifdef PGIS_X3D_OUTERMOST_TAGS
	ptr += sprintf(ptr, "</%sMultiGeometry>", defid);
#endif

	return (ptr-output);
}

/*
 * Don't call this with single-geoms inspected!
 */
static char *
x3d_3_collection(GEOSGeom col, int precision, int opts, const char *defid)
{
	char *x3d;
	size_t size;

	size = x3d_3_collection_size(col, precision, opts, defid);
	x3d = GDKmalloc(size);
	x3d_3_collection_buf(col, x3d, precision, opts, defid);
	return x3d;
}


/** In X3D3, coordinates are separated by a space separator
 */
static size_t
geom_toX3D3(GEOSGeom geom, char *output, int precision, int opts, int is_closed)
{
	uint32_t i;
	char *ptr;
	char x[OUT_MAX_DIGS_DOUBLE+OUT_MAX_DOUBLE_PRECISION+1];
	char y[OUT_MAX_DIGS_DOUBLE+OUT_MAX_DOUBLE_PRECISION+1];
	char z[OUT_MAX_DIGS_DOUBLE+OUT_MAX_DOUBLE_PRECISION+1];
	const GEOSCoordSequence* gcs_new = GEOSGeom_getCoordSeq(geom);
	uint32_t npoints;

	ptr = output;

	if ( GEOS_getWKBOutputDims(geom) == 2)
	{
		GEOSCoordSeq_getSize(gcs_new, &npoints);
		for (i=0; i<npoints; i++)
		{
			/** Only output the point if it is not the last point of a closed object or it is a non-closed type **/
			if ( !is_closed || i < (npoints - 1) )
			{
				GEOSGeom point = (GEOSGeom) GEOSGetGeometryN(geom, i);
				double pt_x, pt_y;
				GEOSGeomGetX(point, &pt_x);
				GEOSGeomGetY(point, &pt_y);

				if (fabs(pt_x) < OUT_MAX_DOUBLE)
					sprintf(x, "%.*f", precision, pt_x);
				else
					sprintf(x, "%g", pt_x);
				trim_trailing_zeros(x);

				if (fabs(pt_y) < OUT_MAX_DOUBLE)
					sprintf(y, "%.*f", precision, pt_y);
				else
					sprintf(y, "%g", pt_y);
				trim_trailing_zeros(y);

				if ( i )
					ptr += sprintf(ptr, " ");
					
				if ( ( opts & LW_X3D_FLIP_XY) )
					ptr += sprintf(ptr, "%s %s", y, x);
				else
					ptr += sprintf(ptr, "%s %s", x, y);
			}
		}
	}
	else
	{
		for (i=0; i<npoints; i++)
		{
			/** Only output the point if it is not the last point of a closed object or it is a non-closed type **/
			if ( !is_closed || i < (npoints - 1) )
			{
				GEOSGeom point =(GEOSGeom ) GEOSGetGeometryN(geom, i);
				double pt_x, pt_y, pt_z;
				GEOSGeomGetX(point, &pt_x);
				GEOSGeomGetY(point, &pt_y);
				GEOSGeomGetZ(point, &pt_z);

				if (fabs(pt_x) < OUT_MAX_DOUBLE)
					sprintf(x, "%.*f", precision, pt_x);
				else
					sprintf(x, "%g", pt_x);
				trim_trailing_zeros(x);

				if (fabs(pt_y) < OUT_MAX_DOUBLE)
					sprintf(y, "%.*f", precision, pt_y);
				else
					sprintf(y, "%g", pt_y);
				trim_trailing_zeros(y);

				if (fabs(pt_z) < OUT_MAX_DOUBLE)
					sprintf(z, "%.*f", precision, pt_z);
				else
					sprintf(z, "%g", pt_z);
				trim_trailing_zeros(z);

				if ( i )
					ptr += sprintf(ptr, " ");

				if ( ( opts & LW_X3D_FLIP_XY) )
					ptr += sprintf(ptr, "%s %s %s", y, x, z);
				else
					ptr += sprintf(ptr, "%s %s %s", x, y, z);
			}
		}
	}

	return ptr-output;
}



/**
 * Returns maximum size of rendered pointarray in bytes.
 */
static size_t
geom_X3Dsize(GEOSGeom geom, int precision)
{
	const GEOSCoordSequence* gcs_new = GEOSGeom_getCoordSeq(geom);
	uint32_t npoints;
	GEOSCoordSeq_getSize(gcs_new, &npoints);
	
	if (GEOS_getWKBOutputDims(geom) == 2)
		return (OUT_MAX_DIGS_DOUBLE + precision + sizeof(" "))
		       * 2 * npoints;

	return (OUT_MAX_DIGS_DOUBLE + precision + sizeof(" ")) * 3 * npoints;
}

/*
 *  * Removes trailing zeros and dot for a %f formatted number.
 *   * Modifies input.
 *    */
static void
trim_trailing_zeros(char *str)
{
        char *ptr, *totrim=NULL;
        int len;
        int i;

        ptr = strchr(str, '.');
        if ( ! ptr ) return; /* no dot, no decimal digits */

        len = strlen(ptr);
        for (i=len-1; i; i--)
        {
                if ( ptr[i] != '0' ) break;
                totrim=&ptr[i];
        }
        if ( totrim )
        {
                if ( ptr == totrim-1 ) *ptr = '\0';
                else *totrim = '\0';
        }
}

static void GEOSGeomGetZ(GEOSGeom geom, double *z) {
	const GEOSCoordSequence* gcs_new;
	gcs_new = GEOSGeom_getCoordSeq(geom);	
	GEOSCoordSeq_getZ(gcs_new, 0, z);
}

