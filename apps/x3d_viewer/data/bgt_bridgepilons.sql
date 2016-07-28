declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
declare _segmentlength integer;

set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;
set _segmentlength = 10;

WITH
bounds_ AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_unclassified_ AS (
	SELECT x, y,z
	FROM ahn3, bounds_ 
	WHERE 
        --ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992),10) --patches should be INSIDE bounds_
        [geom] DWithin [x, y, z, 28992,10]
        AND c = 26
),
footprints_ AS (
	SELECT 
        --ST_Force3D(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)) as geom,
        ST_Force3D(a.wkt) as geom,
    	a.ogc_fid as id, 'pijler' as type
	FROM bgt_overbruggingsdeel a, bounds_ b
	WHERE 1 = 1
	AND typeoverbruggingsdeel = 'pijler'
	--AND ST_Intersects(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992), b.geom)
	AND [a.wkt] Intersects [b.geom]
	--AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), b.geom)
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
),
papoints_ AS ( --get points from intersecting patches
	SELECT 
		a.type,
		a.id,
		x, y, z,
		geom
	FROM footprints_ a
	--LEFT JOIN pointcloud_unclassified_ b ON (ST_Intersects(a.geom, geometry(b.pa)))
	--LEFT JOIN pointcloud_unclassified_ b ON (ST_Intersects(a.geom, x, y, z,28992))
	LEFT JOIN pointcloud_unclassified_ b ON ([a.geom] Intersects [x, y, z,28992])
),
papatch_ AS (
	SELECT
		id,
		geom,
		type,
		z,
		min(z) as min,
        max(z) as max,
        avg(z) as avg
	FROM papoints_
	WHERE 
        --ST_Intersects(geometry(pt), geom)
        --ST_Intersects(geom, x, y,z, 28992)
        [geom] Intersects [x, y,z, 28992]
	GROUP BY id, geom, type, z
),
filter_ AS (
	SELECT
		id,
		type,
		geom,
		--is dit filter_ nog nodig?
		--PC_FilterBetween(pa, 'z',avg-1, avg+1) pa, 
        z,
		min, max, avg
	FROM papatch_
    WHERE z between avg-1 and avg+1
),
stats_ AS (
	SELECT  id, geom,type,
		max,
		0 as min,
		avg,
		avg(z) as z
	FROM filter_
	GROUP BY id, geom, type, max, min, avg, z
),
polygons_ AS (
	SELECT id, type,ST_Extrude(ST_Tesselate(ST_Translate(geom,0,0, min)), 0,0,avg-min -0.1) as geom FROM stats_
)
SELECT id, type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons_.geom, 4.0, 0) as geom FROM polygons_;
