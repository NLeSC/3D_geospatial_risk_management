declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816;
set _east = 93916;
set _south = 463891;
set _north = 463991;

drop table bounds;
create table bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
) with data;

drop table pointcloud_building;
create table pointcloud_building AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816 and 93916 and
    y between 463891 and 463991 and
    --ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992),10) --patches should be INSIDE bounds
    Contains(geom, x, y)
    and c = 1
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(a.geom) as geom,
	a.ogc_fid as id
	FROM bgt_polygons a, bounds b
	WHERE 1 = 1
	AND type = 'muur'
	AND ST_Intersects(a.geom, b.geom)
	AND ST_Intersects(ST_Centroid(a.geom), b.geom)
) with data;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT a.id, x, y, z, geom as footprint
	FROM footprints a, pointcloud_building b
	--LEFT JOIN pointcloud_building b ON (ST_Intersects(a.geom, ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992)))
	WHERE (ST_Intersects(a.geom, ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992)))
) with data;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a, pointcloud_building b
	--LEFT JOIN pointcloud_building b ON (ST_Intersects(a.geom, ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992)))
	WHERE (ST_Intersects(a.geom, ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992)))
	GROUP BY a.id
) with data;

drop table footprintpatch;
create table footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints WHERE ST_Intersects(footprint, ST_SetSRID(ST_MakePoint(x, y, z), 28992))
	--GROUP BY id, footprint
) with data;

drop table stats;
create table stats AS (
	SELECT  a.id, footprint,
		avg(z) as max,
		min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
) with data;

drop table polygons;
create table polygons AS (
	SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min), 0,0,max-min) as geom
    FROM stats
) with data;

SELECT id,'building' as type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom, 4.0, 0) as  geom FROM polygons;
