declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816;
set _east = 93916;
set _south = 463891;
set _north = 463991;

WITH 
bounds AS (
    SELECT ST_SetSRID(ST_MakeEnvelope(_west, _south, _east, _north, 28992), 4326) as geom 
), 
pointcloud AS (
	SELECT x, y, z 
	FROM ahn3, bounds 
	WHERE 
    --x between _west and _east and
    --y between _south and _north and
    x between 93816 and 93916 and
    y between 463891 and 463991 and
	ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 4326), 10)
	and c = 6
),
footprints AS (
	--SELECT ST_Force3D(ST_GeometryN(wkt,1)) as geom,
	SELECT ST_GeometryN(wkt,1) as geom,
	a.gml_id as id,
	0 as bouwjaar
	FROM bgt_buildingpart a, bounds b
	WHERE 1 = 1
	AND ST_Area(a.wkt) > 30
	AND ST_Intersects(ST_SetSRID(a.wkt, 4326), b.geom)
	AND ST_Intersects(ST_SetSRID(ST_Centroid(a.wkt), 4326), b.geom)
	AND ST_IsValid(a.wkt)
),
--papoints AS ( --get points from intersecting patches
--	SELECT 
--		a.id,
--		PC_Explode(b.pa) pt,
--		geom footprint
--	FROM footprints a
--	LEFT JOIN pointcloud b ON (ST_Intersects(a.geom, geometry(b.pa)))
--),
stats_fast AS (
	SELECT 
		footprints.id,
		bouwjaar,
		geom as footprint,
        max(z) as max,
        min(z) as min
	FROM footprints, pointcloud
    WHERE ST_Intersects(geom, ST_MakePoint(x, y, z))
	GROUP BY footprints.id, footprint, bouwjaar
),
polygons AS (
	SELECT 
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min)
			, 0,0,max-min -2)
		) as geom
        FROM stats_fast
)
SELECT id, 'building' as "type", 'red' as color, ST_AsX3D((p.geom), 4.0, 0) as geom FROM polygons p;
