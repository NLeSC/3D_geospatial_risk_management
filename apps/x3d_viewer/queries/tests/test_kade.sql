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

drop table pointcloud_ground;
create table pointcloud_ground AS (
	--SELECT PC_FilterEquals(pa,'classification',2) pa --ground points
    SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_DWithin(geom, ST_MakePoint(x, y, z), 10)
    [geom] DWithin [x, y, z, 28992, 10]
    and c =2
) WITH DATA;

drop table pointcloud_all;
create table pointcloud_all AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_DWithin(geom, ST_MakePoint(x, y, z), 10)
    [geom] DWithin [x, y, z, 28992, 10]
) WITH DATA;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.wkt, b.geom)) as geom,
	a.ogc_fid as id
	FROM bgt_scheiding a, bounds b
	WHERE 1 = 1
	--AND bgt_type = 'kademuur'
	AND [a.wkt] Intersects [b.geom]
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
) WITH DATA;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		x, y, z,
		geom as footprint
	FROM footprints a
	LEFT JOIN pointcloud_ground b
    --ON (ST_Intersects(a.geom, Geometry(b.pa)))
    ON ([a.geom] Intersects [x, y, z, 28992])
) WITH DATA;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a
	LEFT JOIN pointcloud_all b
    -- ON (ST_Intersects(a.geom, Geometry(b.pa)))
    ON [a.geom] Intersects [x, y, z, 28992]
    GROUP BY a.id
) WITH DATA;

drop table footprintpatch;
create table footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints 
    WHERE
        [footprint] Intersects [x, y, z, 28992]
	--GROUP BY id, footprint
) WITH DATA;

drop table stats;
create table stats AS (
	SELECT  a.id, footprint, max(z) as max, min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min)), 0,0,max-min) as geom
    FROM stats
) WITH DATA;
SELECT id, 'kade' as typ, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons p;
