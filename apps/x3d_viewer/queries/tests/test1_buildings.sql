declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816;
set _east = 93916;
set _south = 463891;
set _north = 463991;

drop table ahn3T;
create table ahn3T (x decimal(9,3), y decimal(9,3), z decimal(9,3), a int, i int, n int, r int, c int, p int, e int, d int, M int);

drop table bounds;
create table bounds AS 	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom with data;

drop table pointcloud;
create table pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
	--ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
	--ST_DWithin(geom, ST_geomFromText('Point( 10.0 11.0 12.0)', 28992), 10) --patches should be INSIDE bounds
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
	--ST_DWithin(geom, ST_SetSRID(ST_POINT(x, y), 4326), 10) --patches should be INSIDE bounds
	--ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 4326), 10) --patches should be INSIDE bounds
	Contains(geom, x, y) --patches should be INSIDE bounds
	--classification = 6
	and c = 6
) with data;

drop table footprints;
create table footprints AS (
	--SELECT ST_Force3D(ST_GeometryN(wkt,1)) as geom,
	SELECT ST_GeometryN(wkt,1) as geom,
    	a.gml_id as id,
	0 as bouwjaar
	FROM bgt_buildingpart a, bounds b
	WHERE 1 = 1
	--AND a.ogc_fid = 688393 --DEBUG
	AND ST_Area(a.wkt) > 5
	AND ST_Intersects(a.wkt, b.geom)
	AND ST_Intersects(ST_Centroid(a.wkt), b.geom)
	AND ST_IsValid(a.wkt)
) with data;

select * from footprints;

drop table papoints;
create table papoints AS (
	SELECT a.id, x, y, z, geom as footprint
	FROM footprints a
	--LEFT JOIN pointcloud b ON (ST_Intersects(a.geom, ST_MakePoint(x, y, z)))
	LEFT JOIN pointcloud b ON (ST_Intersects(a.geom, ST_POINT(x, y)))
) with data;

drop table stats_fast;
create table stats_fast AS (
	SELECT
		footprints.id,
		bouwjaar,
		geom as footprint,
		--PC_PatchAvg(PC_Union(pa),'z') as max,
        max(z) as max,
		--PC_PatchMin(PC_Union(pa),'z') as min,
        min(z) as min
	FROM footprints
	--LEFT JOIN ahn_pointcloud.ahn2objects ON (ST_Intersects(geom, geometry(pa)))
	--LEFT JOIN pointcloud ON (ST_Intersects(geom, ST_MakePoint(x, y, z)))
	--LEFT JOIN pointcloud ON (ST_Intersects(geom, ST_POINT(x, y)))
	--, pointcloud WHERE ST_Intersects(geom, ST_POINT(x, y))
	, pointcloud WHERE ST_Intersects(geom, ST_MakePoint(x, y, z))
	GROUP BY footprints.id, footprint, bouwjaar
) with data;

drop table polygons;
create table polygons AS (
	SELECT
		id, bouwjaar, ST_Tesselate
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min)
			, 0,0,max-min -2)
		) as geom
	FROM stats_fast
	--SELECT ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
) with data;


drop table polygons;
create table polygons AS ( SELECT id, bouwjaar, ( ST_Extrude( ST_Translate(footprint,0,0, min), 0,0,max-min -2)) as geom FROM stats_fast) with data;

drop table polygons_test;
create table polygons_test AS ( SELECT id, bouwjaar, (ST_Extrude( ST_Translate(footprint,0,0, min), 0,0,max-min -2)) as geom FROM stats_fast) with data;


SELECT id, 'building' as "type", 'red' as color, ST_AsX3D((p.geom), 4.0, 0) as geom FROM polygons_test p;
