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
) with data;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT x, y, z
	FROM ahn3, bounds 
	WHERE 
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    Contains(geom, x, y)
    and c =2
) with data;

drop table pointcloud_all;
create table pointcloud_all AS (
	SELECT x, y, z 
	FROM ahn3, bounds 
	WHERE 
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    Contains(geom, x, y)
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.geom, b.geom)) as geom,
	a.ogc_fid as id
	FROM bgt_polygons a, bounds b
	WHERE 1 = 1
	--AND (type = 'kademuur' OR class = 'border') 
	AND ST_Intersects(a.geom, b.geom)
	AND ST_Intersects(ST_Centroid(a.geom), b.geom)
) with data;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT 
		a.id,
		x, y, z,
		geom as footprint
	FROM footprints a, pointcloud_ground b
	where ST_Intersects(a.geom, ST_MakePoint(b.x, b.y, b.z, 28992))
) with data;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a, pointcloud_all b
	--LEFT JOIN pointcloud_all b ON (ST_Intersects(a.geom, Geometry(b.pa)))
	WHERE
        ST_Intersects(a.geom,  ST_MakePoint(b.x, b.y, b.z, 28992))
	GROUP BY a.id
) with data;

drop table footprintpatch;
create table footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints 
    WHERE 
        ST_Intersects(footprint, ST_MakePoint(x, y, z, 28992))
	--GROUP BY id, footprint
) with data;

drop table stats;
create table stats AS (
	SELECT  a.id, footprint, max(z) as max, min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
) with data;

--Crash
drop table polygons_kade;
create table polygons_kade AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min)), 0,0,max-min) as geom
    FROM stats
) with data;

SELECT id, 'kade' as typ, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons_kade p;
