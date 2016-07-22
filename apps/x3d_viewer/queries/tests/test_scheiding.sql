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
) WITH DATA;

drop table pointcloud_building;
create table pointcloud_building AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816 and 93916 and
    y between 463891 and 463991 and
    --ST_DWithin(geom, ST_MakePoint(x, y, z),10) --patches should be INSIDE bounds
    [geom] DWithin [x, y, z,10] and --patches should be INSIDE bounds
    and c = 1
    and r = 1
    and i > 150
) WITH DATA;

drop table footprints;
create table footprints AS (
	SELECT a.ogc_fid as id, 'border' as class, a.bgt_type as type,
    --ST_Force3D(ST_CurveToLine(a.wkt)) as geom
    ST_Force3D(a.wkt) as geom
	FROM bgt_scheiding a
    LEFT JOIN bgt_overbruggingsdeel b
    ON ([a.wkt] Intersects [b.wkt]) AND St_Contains(ST_buffer((b.wkt),1), (a.wkt))
    , bounds c
	WHERE a.relatieveHoogteligging > -1
	AND bgt_type = 'muur'
    AND (b.wkt) Is Null
	AND [a.wkt] Intersects [c.geom]
	AND [ST_Centroid(a.wkt)] Intersects [c.geom]
) WITH DATA;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT a.id, x, y, z, geom as footprint
	FROM footprints a
	LEFT JOIN pointcloud_building b
    --ON (ST_Intersects(a.geom, b.x, b.y, b.z, 28992))
    ON [a.geom] Intersects [b.x, b.y, b.z, 28992]
) WITH DATA;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a
	LEFT JOIN pointcloud_building b
    --ON (ST_Intersects(a.geom, b.x, b.y, b.z, 28992))
    ON [a.geom] Intersects [b.x, b.y, b.z, 28992]
	GROUP BY a.id
) WITH DATA;

drop table footprintpatch;
create table footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints
    WHERE
    --ST_Intersects(footprint, ST_SetSRID(ST_MakePoint(x, y, z), 28992))
    [footprint] Intersects [x, y, z, 28992]
	--GROUP BY id, footprint
) WITH DATA;

drop table stats;
create table stats AS (
	SELECT  a.id, footprint,
		avg(z) as max,
		min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min), 0,0,max-min) as geom
    FROM stats
	--SELECT id, ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
) WITH DATA;

SELECT id,'building' as type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom, 4.0, 0) as  geom FROM polygons;
