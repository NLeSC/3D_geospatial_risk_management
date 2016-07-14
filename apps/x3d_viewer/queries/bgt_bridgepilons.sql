WITH 
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
),
pointcloud_unclassified AS (
	SELECT PC_FilterEquals(pa,'classification',26) pa --unclassified points 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
),
footprints AS (
	SELECT ST_Force3D(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)) geom,
	a.ogc_fid id, 'pijler'::text as type
	FROM bgt_import2.overbruggingsdeel_2dactueel a, bounds b
	WHERE 1 = 1
	AND typeoverbruggingsdeel = 'pijler'
	AND ST_Intersects(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992), b.geom)
	AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), b.geom)
),
papoints AS ( --get points from intersecting patches
	SELECT 
		a.type,
		a.id,
		PC_Explode(b.pa) pt,
		geom
	FROM footprints a
	LEFT JOIN pointcloud_unclassified b ON (ST_Intersects(a.geom, geometry(b.pa)))
),
papatch AS (
	SELECT
		id,
		type,
		geom,
		PC_Patch(pt) pa,
		PC_PatchMin(PC_Patch(pt), 'z') min,
		PC_PatchMax(PC_Patch(pt), 'z') max,
		PC_PatchAvg(PC_Patch(pt), 'z') avg
	FROM papoints
	WHERE ST_Intersects(geometry(pt), geom)
	GROUP BY id, geom, type
),
filter AS (
	SELECT
		id,
		type,
		geom,
		--is dit filter nog nodig?
		PC_FilterBetween(pa, 'z',avg-1, avg+1) pa, 
		min, max, avg
	FROM papatch
),
stats AS (
	SELECT  id, geom,type,
		max,
		0 as min,
		avg,
		PC_PatchAvg(pa,'z') z
	FROM filter
	GROUP BY id, geom, type, max, min, avg, z
),
polygons AS (
	SELECT id, type,ST_Extrude(ST_Tesselate(ST_Translate(geom,0,0, min)), 0,0,avg-min -0.1) geom FROM stats
)
SELECT id, type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom) geom
FROM polygons;