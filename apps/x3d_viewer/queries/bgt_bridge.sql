WITH 
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
pointcloud AS (
	SELECT PC_FilterEquals(pa,'classification',26) pa --bridge points 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
),
--TODO: introduce extra vertices where brdge pilon intersects
footprints AS (
	SELECT nextval('counter') id, ogc_fid fid, 'bridge'::text AS class, 'dek'::text AS type,
	  ST_CurveToLine(a.wkb_geometry) geom
	FROM bgt_import2.overbruggingsdeel_2dactueel a, bounds b
	WHERE 1 = 1
	AND typeoverbruggingsdeel = 'dek'
	AND ST_Intersects(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992), b.geom)
	AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), b.geom)
)
,roads AS (
	SELECT nextval('counter') id,a.ogc_fid, 'bridge'::text AS class, a.bgt_functie as type, 
		a.wkb_geometry geom
	FROM bgt_import2.wegdeel_2d a
	LEFT JOIN bgt_import2.overbruggingsdeel_2d b
	ON (St_Intersects((a.wkb_geometry), (b.wkb_geometry)) AND St_Contains(ST_buffer((b.wkb_geometry),1), (a.wkb_geometry)))
	,bounds c
	WHERE a.relatieveHoogteligging > -1
	AND ST_CurveToLine(b.wkb_geometry) Is Not Null
	AND a.eindregistratie Is Null
	AND b.eindregistratie Is Null
	AND ST_Intersects(c.geom, a.wkb_geometry)
	AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), c.geom)
)
,polygons AS (
	SELECT * FROM footprints
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
	UNION ALL
	SELECT * FROM roads
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
)
,rings AS (
	SELECT id, fid, type, geom as geom0, (ST_DumpRings(geom)).*
	FROM polygons
)
,edge_points AS (
	SELECT id, fid, type, geom0, path ring, (ST_Dumppoints(geom)).* 
	FROM rings
)
,edge_points_patch AS ( --get closest patch to every vertex
	SELECT a.id, a.fid, a.type, a.geom0, a.path, a.ring, a.geom,  --find closes patch to point
	PC_Explode(COALESCE(b.pa, --if not intersection, then get the closest one 
		(
		SELECT b.pa FROM pointcloud b
		ORDER BY a.geom <#> Geometry(b.pa) 
		LIMIT 1
		)
	)) pt
	FROM edge_points a LEFT JOIN pointcloud b
	ON ST_Intersects(
		a.geom,
		geometry(pa)
	)
),
emptyz AS ( 
	SELECT 
		a.id, a.fid, a.type, a.path, a.ring, a.geom,
		PC_Patch(pt) pa,
		PC_PatchMin(PC_Patch(pt), 'z') min,
		PC_PatchMax(PC_Patch(pt), 'z') max,
		PC_PatchAvg(PC_Patch(pt), 'z') avg
	FROM edge_points_patch a
	WHERE ST_Intersects(geom0, Geometry(pt))
	GROUP BY a.id, a.fid, a.type, a.path, a.ring, a.geom
)
,filter AS (
	SELECT
		a.id, a.fid, a.type, a.path, a.ring, a.geom,
		PC_Get(PC_Explode(PC_FilterBetween(pa, 'z',avg-0.2, avg+0.2)),'z') z
	FROM emptyz a
)
-- assign z-value for every boundary point
,filledz AS ( 
	SELECT id, fid, type, path, ring, ST_Translate(St_Force3D(geom), 0,0,avg(z)) geom
	FROM filter
	GROUP BY id, fid, type, path, ring, geom
	ORDER BY id, ring, path
)
,allrings AS (
	SELECT id, fid, type, ring, ST_AddPoint(ST_MakeLine(geom), First(geom)) geom
	FROM filledz
	GROUP BY id,fid, type, ring
)
,outerrings AS (
	SELECT *
	FROM allrings
	WHERE ring[1] = 0
)
,innerrings AS (
	SELECT id, fid, type, St_Accum(geom) arr
	FROM allrings
	WHERE ring[1] > 0
	GROUP BY id, fid, type
),
polygonsz AS (
	SELECT a.id, a.fid, a.type, COALESCE(ST_MakePolygon(a.geom, b.arr),ST_MakePolygon(a.geom)) geom 
	FROM outerrings a
	LEFT JOIN innerrings b ON a.id = b.id
)
,terrain_polygons AS (
    SELECT * FROM polygonsz
)
,patches AS (
	SELECT t.id, pa
	FROM pointcloud, terrain_polygons t
	WHERE ST_Intersects(
		geom,
		geometry(pa)
	)
),
all_points AS ( -- get pts in every boundary
	SELECT t.id, geometry(PC_Explode(pa)) geom 
	FROM pointcloud, terrain_polygons t
	WHERE ST_Intersects(
		geom,
		geometry(pa)
	)
),
innerpoints AS (
	SELECT a.id, a.geom
	FROM all_points a
	INNER JOIN terrain_polygons b
	ON a.id = b.id 
	AND ST_Intersects(a.geom, b.geom)
	AND Not ST_DWithin(a.geom, ST_ExteriorRing(b.geom),1)
	WHERE random() < (0.1 * _zoom)
	AND (b.type != 'road') 
)
,basepoints AS (
	--SELECT id, geom FROM innerpoints
	--UNION
	SELECT id,geom FROM polygonsz
	WHERE ST_IsValid(geom)
)
,triangles AS (
	SELECT 
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id
)
,assign_triags AS (
	SELECT 	a.id, 
		CASE 
			WHEN b.type != 'dek' THEN ST_Translate(a.geom, 0,0,1) 
			ELSE a.geom
		END as geom, b.type
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
)
SELECT _south::text || _west::text || p.id AS id, p.type as type,
	ST_AsX3D(ST_Collect(p.geom),3) geom
FROM assign_triags p
GROUP BY p.id, p.type