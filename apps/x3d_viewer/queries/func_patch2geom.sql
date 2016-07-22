/*
INPUTS: 
	- PATCH
	- GEOMETRY
OUTPUTS:
	- GEOMETRY Z
*/
DROP FUNCTION IF EXISTS patch_to_geom(inpatch pcpatch, ingeom geometry);
CREATE OR REPLACE FUNCTION patch_to_geom(inpatch pcpatch, ingeom geometry) RETURNS geometry AS 
$$
DECLARE
inpatch pcpatch := inpatch;
ingeom geometry := ingeom;
output geometry;

BEGIN

WITH 
papoints AS (
	SELECT PC_Explode(inpatch) pt
),
rings AS (
	SELECT (ST_DumpRings(ingeom)).*
),
edge_points AS (
	SELECT path ring, (ST_Dumppoints(rings.geom)).* 
	FROM rings
),
emptyz AS ( 
	SELECT a.*, ( 
		SELECT b.pt FROM papoints b
		ORDER BY a.geom <#> Geometry(b.pt)
		LIMIT 1
	) pt
	FROM edge_points a
)
-- assign z-value for every boundary point
,filledz AS ( 
	SELECT path, ring, ST_Translate(St_Force3D(emptyz.geom), 0,0,PC_Get(first(pt),'z')) geom
	FROM emptyz
	GROUP BY path, ring, geom
	ORDER BY ring, path
)
,allrings AS (
	SELECT ring, ST_AddPoint(ST_MakeLine(geom), First(geom)) geom
	FROM filledz
	GROUP BY ring
)
,outerring AS (
	SELECT *
	FROM allrings
	WHERE ring[1] = 0
)
,innerrings AS (
	SELECT St_Accum(allrings.geom) arr
	FROM allrings
	WHERE ring[1] > 0
),
polygonz AS (
	SELECT COALESCE(ST_MakePolygon(a.geom, b.arr),ST_MakePolygon(a.geom)) geom 
	FROM outerring a, innerrings b
)

SELECT polygonz.geom INTO output FROM polygonz;
RETURN output;

END;
$$ LANGUAGE plpgsql;