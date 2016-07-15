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


drop table bounds;
create table bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
) WITH DATA;

drop table mainroads;
create table mainroads AS (
	SELECT a.ogc_fid, 'road'::text AS class, a.bgt_functie as type, ST_Intersection(a.wkb_geometry,c.geom) geom 
	FROM bgt_import2.wegdeel_2d a
	LEFT JOIN bgt_import2.overbruggingsdeel_2d b
	ON (St_Intersects((a.wkb_geometry), (b.wkb_geometry)) AND St_Contains(ST_buffer((b.wkb_geometry),1), (a.wkb_geometry)))
	,bounds c
	WHERE a.relatieveHoogteligging = 0
	AND ST_CurveToLine(b.wkb_geometry) Is Null
	AND a.eindregistratie Is Null
	AND b.eindregistratie Is Null
	AND ST_Intersects(geom, a.wkb_geometry)
) WITH DATA;

drop table auxroads;
create table auxroads AS (
	SELECT ogc_fid, 'road'::text AS class, bgt_functie as type, ST_Intersection(wkb_geometry,geom) geom
	FROM bgt_import2.ondersteunendwegdeel_2d, bounds
	WHERE relatieveHoogteligging = 0
	AND eindregistratie Is Null
	AND ST_Intersects(geom, wkb_geometry)
) WITH DATA;

drop table tunnels;
create table tunnels AS (
	SELECT ogc_fid, 'road'::text AS class, 'tunnel'::text as type, ST_Intersection(wkb_geometry,geom) geom
	FROM bgt_import2.tunneldeel_2d, bounds
	WHERE eindregistratie Is Null
	AND ST_Intersects(geom, wkb_geometry)
) WITH DATA;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_Intersects(geom, Geometry(pa))
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM mainroads
	UNION ALL
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM auxroads
	UNION ALL
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM tunnels
) WITH DATA;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, fid, type, class, patch_to_geom(PC_Union(b.pa), geom) geom
	FROM polygons a 
	LEFT JOIN pointcloud_ground b
	ON ST_Intersects(geom,Geometry(b.pa))
	GROUP BY id, fid, type, class, geom
) WITH DATA;

drop table basepoints;
create table basepoints AS (
	SELECT id,geom FROM polygonsz
	WHERE ST_IsValid(geom)
) WITH DATA;

drop table triangles;
create table triangles AS (
	SELECT 
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id
) WITH DATA;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
) WITH DATA;


SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),5.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
