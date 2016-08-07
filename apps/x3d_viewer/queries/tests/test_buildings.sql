declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;


drop table bounds;
create table bounds AS (
    SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
) WITH DATA;

drop table pointcloud;
create table pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
	--ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992), 10)
	Contains(geom, x, y)
	and c = 6
) WITH DATA;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(wkt, 0.4),1)) as geom,
	a.ogc_fid as id,
	0 as bouwjaar
	FROM bgt_pand a, bounds b
	WHERE 1 = 1
	AND ST_Area(a.wkt) > 30
	AND [a.wkt] Intersects [b.geom]
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
	AND ST_IsValid(a.wkt)
) WITH DATA;

drop table stats_fast;
create table stats_fast AS (
	SELECT
		footprints.id,
		bouwjaar,
		geom as footprint,
        max(z) as max,
        min(z) as min
	FROM footprints
    LEFT JOIN pointcloud ON
        --ST_Intersects(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992))
        ST_Intersects(geom, x, y, z, 28992)
	GROUP BY footprints.id, footprint, bouwjaar
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min - 1)
			, 0,0,max-min -1)
		) as geom
        FROM stats_fast
) WITH DATA;

SELECT id, 'building' as "type", 'red' as color, ST_AsX3D((p.geom), 4.0, 0) as geom FROM polygons p;
