#include "geom_sfcgal.h"

static sfcgal_geometry_t* geom_to_SFCGAL(str *ret, GEOSGeom geom, int type);

#if 0
/*
 * Mapping between SFCGAL and GEOM types
 *
 * Throw an error if type is unsupported
 */
static int
SFCGAL_type_to_geom_type(sfcgal_geometry_type_t type)
{
	switch (type)
	{
	case SFCGAL_TYPE_POINT:
		return wkbPoint_mdb;

	case SFCGAL_TYPE_LINESTRING:
		return wkbLineString_mdb;

	case SFCGAL_TYPE_POLYGON:
		return wkbPolygon_mdb;

	case SFCGAL_TYPE_MULTIPOINT:
		return wkbMultiPoint_mdb;

	case SFCGAL_TYPE_MULTILINESTRING:
		return wkbMultiLineString_mdb;

	case SFCGAL_TYPE_MULTIPOLYGON:
		return wkbMultiPolygon_mdb;

	case SFCGAL_TYPE_MULTISOLID:
		return wkbGeometryCollection_mdb;  /* Nota: PolyhedralSurface closed inside
             				   aim is to use true solid type as soon
	           			   as available in OGC SFS */

	case SFCGAL_TYPE_GEOMETRYCOLLECTION:
		return wkbGeometryCollection_mdb;

#if 0
	case SFCGAL_TYPE_CIRCULARSTRING:
		return CIRCSTRINGTYPE;

	case SFCGAL_TYPE_COMPOUNDCURVE:
		return COMPOUNDTYPE;

	case SFCGAL_TYPE_CURVEPOLYGON:
		return CURVEPOLYTYPE;

	case SFCGAL_TYPE_MULTICURVE:
		return MULTICURVETYPE;

	case SFCGAL_TYPE_MULTISURFACE:
		return MULTISURFACETYPE;
#endif

	case SFCGAL_TYPE_POLYHEDRALSURFACE:
		return wkbPolyehdralSurface_mdb;

	case SFCGAL_TYPE_TRIANGULATEDSURFACE:
		return wkbTin_mdb;

	case SFCGAL_TYPE_TRIANGLE:
		return wkbTriangle_mdb;

	default:
		lwerror("SFCGAL_type_to_geom_type: Unknown Type");
		return 0;
	}
}
#endif

static void GEOSGeomGetZ(GEOSGeom geom, double *z) {
	const GEOSCoordSequence* gcs_new;
	gcs_new = GEOSGeom_getCoordSeq(geom);	
	GEOSCoordSeq_getZ(gcs_new, 0, z);
}

static sfcgal_geometry_t *
geom_to_SFCGAL(str *ret, GEOSGeom geom, int type)
{
	int is_3d;
	double point_x = 0.0, point_y = 0.0, point_z = 0.0;
	int i;
	*ret = MAL_SUCCEED;

	is_3d = GEOS_getWKBOutputDims(geom) == 3;

	switch (type)
	{
	case wkbPoint_mdb:
	{
		GEOSGeomGetX(geom, &point_x);
		GEOSGeomGetY(geom, &point_y);
		if (is_3d) {
			GEOSGeomGetZ(geom, &point_z);
			return sfcgal_point_create_from_xyz(point_x, point_y, point_z);
		} else
			return sfcgal_point_create_from_xy(point_x, point_y);
	}
	break;

	case wkbLineString_mdb:
	{
		sfcgal_geometry_t* line = sfcgal_linestring_create();
		int numPoints = GEOSGeomGetNumPoints(geom);
		for (i = 0; i < numPoints; i++)
		{
			GEOSGeom pointG = GEOSGeomGetPointN(geom, i);
			GEOSGeomGetX(pointG, &point_x);
			GEOSGeomGetY(pointG, &point_y);
			if (is_3d)
			{
				GEOSGeomGetZ(pointG, &point_z);
				sfcgal_linestring_add_point(line,
				                            sfcgal_point_create_from_xyz(point_x, point_y, point_z));
			}
			else
			{
				sfcgal_linestring_add_point(line,
				                            sfcgal_point_create_from_xy(point_x, point_y));
			}
		}

		return line;
	}
	break;

	case wkbTriangle_mdb:
	{
		GEOSGeometry* pointG;
		sfcgal_geometry_t* triangle = sfcgal_triangle_create();

		pointG = GEOSGeomGetPointN(geom, 0);
		GEOSGeomGetX(pointG, &point_x);
		GEOSGeomGetY(pointG, &point_y);
		if (is_3d){
			GEOSGeomGetZ(pointG, &point_z);
			sfcgal_triangle_set_vertex_from_xyz(triangle, 0, point_x, point_y, point_z);
		} else
			sfcgal_triangle_set_vertex_from_xy (triangle, 0, point_x, point_y);

		pointG = GEOSGeomGetPointN(geom, 1);
		GEOSGeomGetX(pointG, &point_x);
		GEOSGeomGetY(pointG, &point_y);
		if (is_3d){
			GEOSGeomGetZ(pointG, &point_z);
			sfcgal_triangle_set_vertex_from_xyz(triangle, 1, point_x, point_y, point_z);
		} else
			sfcgal_triangle_set_vertex_from_xy (triangle, 1, point_x, point_y);


		pointG = GEOSGeomGetPointN(geom, 2);
		GEOSGeomGetX(pointG, &point_x);
		GEOSGeomGetY(pointG, &point_y);
		if (is_3d){
			GEOSGeomGetZ(pointG, &point_z);
			sfcgal_triangle_set_vertex_from_xyz(triangle, 2, point_x, point_y, point_z);
		} else
			sfcgal_triangle_set_vertex_from_xy (triangle, 2, point_x, point_y);

		return triangle;
	}
	break;

	/* Other SFCGAL types should not be called directly ... */
	default:
		*ret = createException(MAL, "geom_to_sfcgal", "Unknown geometry type");
		return NULL;
	}
}


str
geos2sfcgal(sfcgal_geometry_t **res, GEOSGeom geosGeometry)
{
	int i, numGeometries = GEOSGetNumGeometries(geosGeometry);
	int type = GEOSGeomTypeId(geosGeometry)+1;
	sfcgal_geometry_t* ret_geom = NULL;
	str ret = MAL_SUCCEED;

	switch (type)
	{
	case wkbPoint_mdb:
	{
		if (GEOSisEmpty(geosGeometry) == 1) {
			*res = sfcgal_point_create();
			break;
		}
		*res = geom_to_SFCGAL(&ret, geosGeometry, wkbPoint_mdb);
	}
	break;

	case wkbLineString_mdb:
	{
		if (GEOSisEmpty(geosGeometry) == 1) {
			*res = sfcgal_linestring_create();
			break;
		}
		*res = geom_to_SFCGAL(&ret, geosGeometry, wkbLineString_mdb);
	}
	break;

	case wkbTriangle_mdb:
	{
		if (GEOSisEmpty(geosGeometry) == 1) {
			res = sfcgal_triangle_create();
			break;
		}
		*res = geom_to_SFCGAL(&ret, geosGeometry, wkbTriangle_mdb);
	}
	break;

	case wkbPolygon_mdb:
	{
		int numInteriorRings = GEOSGetNumInteriorRings(geosGeometry);
		sfcgal_geometry_t* exterior_ring;

		if (GEOSisEmpty(geosGeometry) == 1) {
			*res = sfcgal_polygon_create();
			break;
		}

		exterior_ring = geom_to_SFCGAL(&ret, *(GEOSGeom*)GEOSGetExteriorRing(geosGeometry), wkbLineString_mdb);
		ret_geom = sfcgal_polygon_create_from_exterior_ring(exterior_ring);

		for (i = 0; i < numInteriorRings; i++)
		{
			sfcgal_geometry_t* ring = geom_to_SFCGAL(&ret, *(GEOSGeom*)GEOSGetInteriorRingN(geosGeometry, i), wkbLineString_mdb);
			sfcgal_polygon_add_interior_ring(ret_geom, ring);
		}
		*res = ret_geom;
	}
	break;

	case wkbMultiPoint_mdb:
	case wkbMultiLineString_mdb:
	case wkbMultiPolygon_mdb:
	case wkbGeometryCollection_mdb:
	{
		if (type == wkbMultiPoint_mdb)
			ret_geom = sfcgal_multi_point_create();
		else if (type == wkbMultiLineString_mdb)
			ret_geom = sfcgal_multi_linestring_create();
		else if (type == wkbMultiPolygon_mdb)
			ret_geom = sfcgal_multi_polygon_create();
		else
			ret_geom = sfcgal_geometry_collection_create();

		for (i = 0; i < numGeometries; i++)
		{
			sfcgal_geometry_t *g;
			ret = geos2sfcgal(&g, *(GEOSGeom*)GEOSGetGeometryN(geosGeometry, i));
			sfcgal_geometry_collection_add_geometry(ret_geom, g);
		}
		*res = ret_geom;
	}
	break;

	case wkbPolyehdralSurface_mdb:
	{
		ret_geom = sfcgal_polyhedral_surface_create();
		for (i = 0; i < numGeometries; i++)
		{
			sfcgal_geometry_t* g;
			ret = geos2sfcgal(&g, *(GEOSGeom*)GEOSGetGeometryN(geosGeometry, i));
			sfcgal_polyhedral_surface_add_polygon(ret_geom, g);
		}
		/* We treat polyhedral surface as the only exterior shell,
		   since we can't distinguish exterior from interior shells ... */
		/*
		 * TODO: Fix this part
		if (FLAGS_GET_SOLID(lwp->flags))
		{
			*res = sfcgal_solid_create_from_exterior_shell(ret_geom);
			break;
		}
		*/

		*res = ret_geom;
	}
	break;

	case wkbTin_mdb:
	{
		ret_geom = sfcgal_triangulated_surface_create();

		for (i = 0; i < numGeometries; i++)
		{
			sfcgal_geometry_t* g;
			ret = geos2sfcgal(&g, *(GEOSGeom*)(GEOSGetGeometryN(geosGeometry, i)));
			sfcgal_triangulated_surface_add_triangle(ret_geom, g);
		}

		*res = ret_geom;
	}
	break;

	default:
		ret = createException(MAL, "geom2cgal", "Unknown geometry type");
		*res = NULL;
	}
	
	return ret;
}
