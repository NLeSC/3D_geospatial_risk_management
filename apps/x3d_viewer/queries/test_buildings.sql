declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93716;
set _east = 93916;
set _south = 463691;
set _north = 463991;

drop table bounds;
create table bounds AS
SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
with data;

drop table pointcloud;
create table pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    --x between _west and _east and
    --y between _south and _north and
    x between 93716 and 93916 and
    y between 463691 and 463991 and
	--ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992), 10)
	Contains(geom, x, y)
	and c = 6
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_GeometryN(wkt,1)) as geom,
	--SELECT ST_GeometryN(wkt,1) as geom,
	a.gml_id as id,
	0 as bouwjaar
	FROM bgt_buildingpart a, bounds b
	WHERE 1 = 1
	AND ST_Area(a.wkt) > 3
	AND ST_Intersects(a.wkt, b.geom)
	AND ST_Intersects(ST_Centroid(a.wkt), b.geom)
	AND ST_IsValid(a.wkt)
) with data;

drop table stats_fast;
create table stats_fast AS (
	SELECT
		footprints.id,
		bouwjaar,
		geom as footprint,
        max(z) as max,
        min(z) as min
	FROM footprints, pointcloud
    WHERE ST_Intersects(geom, ST_MakePoint(x, y, z))
	GROUP BY footprints.id, footprint, bouwjaar
) with data;

drop table polygons;
create table polygons AS (
	SELECT
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min)
			, 0,0,max-min -2)
		) as geom
        FROM stats_fast
) with data;

SELECT id, 'building' as "type", 'red' as color, ST_AsX3D((p.geom), 4.0, 0) as geom FROM polygons p;
