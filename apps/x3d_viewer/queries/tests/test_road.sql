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

drop table bgt_wegdeel_light;
create table bgt_wegdeel_light AS (
	--SELECT a.ogc_fid, 'road' AS class, a.bgt_functie as type, ST_Intersection(a.wkt,c.geom) as geom 
	SELECT a.ogc_fid, 'road' AS class, a.bgt_status as type, a.wkt as wkt, ST_Intersection(a.wkt,c.geom) as geom 
	FROM bgt_wegdeel a, bounds c
	WHERE 
    a.relatieveHoogteligging = 0 AND
	a.eindregistratie Is Null AND
	[geom] Intersects [a.wkt]
) WITH DATA;

drop table mainroads;
create table mainroads AS (
	SELECT a.ogc_fid, a.class, a.type, a.geom 
	FROM bgt_wegdeel_light a
	LEFT JOIN bgt_overbruggingsdeel b
	ON ([a.wkt] Intersects [b.wkt]) AND [ST_buffer((b.wkt),1)] Contains [a.wkt]
	WHERE 
	--AND ST_CurveToLine(b.wkt) Is Null
	b.eindregistratie Is Null
	AND [geom] Intersects [a.wkt]
) WITH DATA;

drop table auxroads;
create table auxroads AS (
	SELECT ogc_fid, 'road' AS class, bgt_functie as type, ST_Intersection(wkt,geom) as geom
	FROM bgt_ondersteunendwegdeel, bounds
	WHERE relatieveHoogteligging = 0
	AND eindregistratie Is Null
	--AND ST_Intersects(geom, wkb_geometry)
	AND [geom] Intersects [wkt]
) WITH DATA;

drop table tunnels;
create table tunnels AS (
	SELECT ogc_fid, 'road' AS class, 'tunnel' as type, ST_Intersection(wkt,geom) as geom
	FROM bgt_tunneldeel, bounds
	WHERE eindregistratie Is Null
	AND [geom] Intersects [wkt]
) WITH DATA;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE 
    --ST_Intersects(geom, x, y, z, 28992) AND
    --[geom] Intersects [x, y, z, 28992] AND
    x between _west and _east and
    y between _south and _north and 
    Contains(geom, x, y) AND
    c = 2
) WITH DATA;

drop table polygons_b;
create table polygons_b AS (
	SELECT ogc_fid as fid, type, class, geom
	FROM mainroads
	UNION ALL
	SELECT ogc_fid as fid, type, class, geom
	FROM auxroads
	UNION ALL
	SELECT ogc_fid as fid, type, class, geom
	FROM tunnels
) WITH DATA;

drop table polygons_dump;
create table polygons_dump AS (
    SELECT parent as fid, polygonWKB as geom
    FROM ST_DUMP((select geom, fid from polygons)) d
) WITH DATA;

drop table polygons;
create table polygons AS (
   select a.fid, a.type, a.class, b.geom
   FROM
   polygons_b a LEFT JOIN polygons_dump b
   ON a.fid = b.fid
) WITH DATA;

drop table polygonsz;
create table polygonsz AS (
	SELECT fid, type, class, geom
	FROM polygons a
	LEFT JOIN pointcloud_ground b
	--ON ST_Intersects(geom,Geometry(b.pa))
	ON [geom] Intersects [x, y, z, 28992]
	WHERE 
        ST_IsValid(geom)
	GROUP BY fid, type, class, geom
) WITH DATA;

drop table edge_points;
create table edge_points AS (
    --SELECT parent as polygon_id, cast(path as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, fid from polygonsz)) d
    SELECT parent as polygon_id, cast((SUBSTRING(path, POSITION(',' IN path)+1)) as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, fid from polygonsz)) d
) WITH DATA;
--insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist FROM _edge_points a, pointcloud_ground b;

drop table emptyz;
create table emptyz AS (
    --SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist FROM edge_points a, pointcloud_ground b WHERE ST_DWithin(a.geom, x, y, z, 28992, 10)
    --SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, x, y, z, 28992) as dist FROM edge_points a, pointcloud_ground b WHERE ST_DWithin(a.geom, x, y, z, 28992, 10)
    SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, x, y, z, 28992) as dist FROM edge_points a, pointcloud_ground b WHERE [a.geom] DWithin [x, y, z, 28992, 10]
) WITH DATA;
--insert into _ranktest select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) as rank from _emptyz;

drop table ranktest;
create table ranktest AS (
    select polygon_id, path, geom, z, dist, RANK() over (PARTITION BY path, geom order by polygon_id, path, dist ASC) as rank from emptyz
    --select polygon_id, path, geom, z, dist, RANK() over (PARTITION BY polygon_id, path, geom) as rank from emptyz
) WITH DATA;
--insert into _filledz select path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from _ranktest where rank = 1 order by path;

drop table filledz;
create table filledz AS (
    --select polygon_id, path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from ranktest where rank = 1 order by path
    select polygon_id, path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from ranktest where rank = 1
) WITH DATA;
--insert into _line_z SELECT ST_MakeLine(geom) as geom FROM _filledz;

drop table line_z;
create table line_z AS (
    SELECT polygon_id, ST_MakeLine(geom) as geom FROM filledz group by polygon_id
) WITH DATA;

drop table basepoints;
create table basepoints AS (
	SELECT polygon_id as id, ST_Triangulate2DZ(ST_Collect(geom),0) as geom FROM line_z
	WHERE ST_IsValid(geom)
    GROUP BY id
) WITH DATA;

drop table triangles;
create table triangles AS (
    SELECT parent as id, ST_SetSRID(ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)), 28992) as geom FROM ST_Dump((select geom, id from basepoints)) a
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
	a.id = b.fid AND
	--ON ST_Contains(b.geom, a.geom)
	[b.geom] Contains [a.geom]
) WITH DATA;


SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),5.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
