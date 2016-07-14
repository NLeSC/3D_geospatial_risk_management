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

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

DROP SEQUENCE "polygon_id";
CREATE SEQUENCE "polygon_id" AS INTEGER;

drop table bounds;
create table bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
) WITH DATA;

drop table pointcloud_water;
create table pointcloud_water AS (
	SELECT 
        x, y, z
	FROM 
        C_30FZ1, bounds 
	WHERE 
        --ST_Intersects(geom, Geometry(pa))
        x between 93816.0 and 93916.0 and
        y between 463891.0 and 463991.0 and
    	Contains(geom, x, y) and
        c = 9
) WITH DATA;

drop table terrain_;
create table terrain_ AS (
	SELECT NEXT VALUE FOR "counter" as id, gml_id as fid, plus_type as typ, 'water' as class, ST_Intersection(a.wkt, b.geom) as geom FROM  bgt_waterdeel a, bounds b WHERE ST_Intersects(a.wkt, b.geom)
) WITH DATA;

drop table terrain_dump;
create table terrain_dump AS (
	SELECT parent as id, polygonWKB as geom FROM ST_Dump((select geom, id from terrain_)) a
) WITH DATA;

drop table terrain;
create table terrain AS (
	SELECT a.id, a.fid, a.typ, a.class, b.geom FROM terrain_ a, terrain_dump b WHERE a.id = b.id
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT NEXT VALUE for "polygon_id" as polygon_id, * FROM terrain WHERE ST_GeometryType(geom) = 'ST_Polygon'
) WITH DATA;

drop table polygonsz;
create table polygonsz AS ( 
	SELECT a.id, a.fid, polygon_id, a.typ, a.class, ST_Translate(ST_Force3D(a.geom), 0,0,0) as geom --fixed level
	FROM polygons a
	--GROUP BY a.id, a.fid, a.typ, a.class, a.geom
) WITH DATA;

drop table basepoints;
create table basepoints AS (
	SELECT id, polygon_id, geom FROM polygonsz WHERE ST_IsValid(geom)
) WITH DATA;

drop table triangles_b;
create table triangles_b AS (
    select polygon_id, id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom from basepoints group by polygon_id, id
) WITH DATA;

drop table triangles;
create table triangles AS (
    SELECT parent as polygon_id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, polygon_id from triangles_b)) a
) WITH DATA;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, d.id, b.typ, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(ST_SetSRID(b.geom, 28992), ST_SetSRID(a.geom, 28992))
	, bounds c, triangles_b d
	WHERE
    --ST_Intersects(ST_Centroid(b.geom) WITH DATA; c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.polygon_id = b.polygon_id and a.polygon_id = d.polygon_id
) WITH DATA;

SELECT p.id AS id, 'water' as type, ST_AsX3D(ST_Collect(p.geom),4.0, 0) as geom FROM assign_triags p GROUP BY id, type;
