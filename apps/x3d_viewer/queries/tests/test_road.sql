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
	SELECT a.ogc_fid, 'road' AS class, a.bgt_functie as type, ST_Intersection(a.wkt,c.geom) as geom 
	FROM bgt_wegdeel a
	LEFT JOIN bgt_overbruggingsdeel b
	--ON (St_Intersects((a.wkt), (b.wkt)) AND St_Contains(ST_buffer((b.wkt),1), (a.wkt)))
	ON ([a.wkt] Intersects [b.wkt]) AND St_Contains(ST_buffer((b.wkt),1), (a.wkt))
	, bounds c
	WHERE a.relatieveHoogteligging = 0
	AND ST_CurveToLine(b.wkt) Is Null
	AND a.eindregistratie Is Null
	AND b.eindregistratie Is Null
	--AND ST_Intersects(geom, a.wkb_geometry)
	AND [geom] Intersects [a.wkt]
) WITH DATA;

drop table auxroads;
create table auxroads AS (
	SELECT ogc_fid, 'road' AS class, bgt_functie as type, ST_Intersection(wkb_geometry,geom) as geom
	FROM bgt_ondersteunendwegdeel, bounds
	WHERE relatieveHoogteligging = 0
	AND eindregistratie Is Null
	--AND ST_Intersects(geom, wkb_geometry)
	AND [geom] Intersects [wkb_geometry]
) WITH DATA;

drop table tunnels;
create table tunnels AS (
	SELECT ogc_fid, 'road' AS class, 'tunnel' as type, ST_Intersection(wkb_geometry,geom) as geom
	FROM bgt_tunneldeel, bounds
	WHERE eindregistratie Is Null
	AND [geom] Intersects [wkb_geometry]
) WITH DATA;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE 
    --ST_Intersects(geom, x, y, z, 28992) AND
    [geom] Intersects [x, y, z, 28992] AND
    c = 2
) WITH DATA;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

drop table polygons;
create table polygons AS (
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM mainroads
	UNION ALL
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM auxroads
	UNION ALL
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM tunnels
) WITH DATA;

drop table polygons_dump;
create table polygons_dump AS (
    SELECT parent as id, polygonWKB as geom
    FROM ST_DUMP((select geom, id from polygons)) d
) WITH DATA;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, fid, type, class, patch_to_geom(x, y, z, geom) as geom
	FROM polygons a,
	LEFT JOIN pointcloud_ground b
	--ON ST_Intersects(geom,Geometry(b.pa))
	ON [geom] Intersects [x, y, z, 28992]
    , polygons_dump c
	WHERE 
        a.id = c.id AND
        ST_IsValid(geom)
	GROUP BY id, fid, type, class, geom
) WITH DATA;

drop table basepoints;
create table basepoints AS (
	SELECT id, ST_Triangulate2DZ(ST_Collect(geom)) FROM polygonsz
	WHERE ST_IsValid(geom)
    GROUP BY id
) WITH DATA;

drop table basepoints_dump;
create table basepoints_dump AS (
    select parent as id, polygonWKB as geom
    FROM ST_DUMP((select geom, id from basepoints)) d
) WITH DATA;

drop table triangles;
create table triangles AS (
	SELECT  id,
		ST_MakePolygon(ST_ExteriorRing(a.geom)) as geom
	FROM basepoints a, basepoints_dump b
    WHERE
    a.id = b.id;
) WITH DATA;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	--INNER JOIN polygons b
	, polygons b
	, bounds c
	WHERE 
    --ST_Intersects(ST_Centroid(b.geom), c.geom) AND
    [ST_Centroid(b.geom)] Intersects [c.geom] AND
	a.id = b.id AND
	--ON ST_Contains(b.geom, a.geom)
	ST_Contains(b.geom, a.geom)
) WITH DATA;


SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),5.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
