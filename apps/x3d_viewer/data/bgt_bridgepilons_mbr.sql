


 with
bounds_ AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_unclassified_ AS (
	SELECT x, y,z
	FROM ahn3, bounds_ 
	WHERE 
    x between _west and _east and
    y between _south and _north and
    [geom] DWithin [x, y, z, 28992,10]
    AND c = 26
),
footprints_ AS (
	SELECT 
        ST_Force3D(a.wkt) as geom,
	a.ogc_fig as id, 'pijler' as type
	FROM bgt_overbruggingsdeel a, bounds_ b
	WHERE
	typeoverbruggingsdeel = 'pijler' AND
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[a.wkt] Intersects [b.geom] AND
	[ST_Centroid(a.wkt)] Intersects [b.geom]
),
papoints_ AS ( --get points from intersecting patches
	SELECT 
		a.type,
		a.id,
		x, y, z,
		geom
	FROM footprints_ a
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
        [geom] Intersects [x, y,z, 28992]
	GROUP BY id, geom, type, z
),
filter_ AS (
	SELECT
		id,
		type,
		geom,
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
	--SELECT id, type,ST_Extrude(ST_Tesselate(ST_Translate(geom,0,0, min)), 0,0,avg-min -0.1) as geom FROM stats_
	SELECT id, type,ST_Extrude(ST_Translate(geom,0,0, min), 0,0,avg-min -0.1) as geom FROM stats_
)
SELECT id, type, 'yellow' as color, ST_AsX3D(polygons_.geom, 4.0, 0) as geom FROM polygons_;
