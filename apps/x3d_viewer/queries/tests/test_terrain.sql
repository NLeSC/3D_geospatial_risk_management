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

WITH

drop table bounds;
create table bounds AS (
    SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992), _segmentlength) as geom
) WITH DATA;

drop table plantcover;
create table plantcover AS (
	SELECT ogc_fid, 'plantcover' AS class, bgt_fysiekvoorkomen as type, St_Intersection(wkt, geom) as geom 
	FROM bgt_begroeidterreindeel, bounds
	WHERE 
    eindregistratie Is Null AND
    --ST_Intersects(geom, wkt) AND
    [geom] Intersects [wkt] AND
    ST_GeometryType(wkt) = 'ST_Polygon'
) WITH DATA;

drop table bare;
create table bare AS (
	SELECT ogc_fid, 'bare' AS class, bgt_fysiekVoorkomen as type, St_Intersection(wkt, geom) as geom
	FROM bgt_onbegroeidterreindeel, bounds
	WHERE
    eindregistratie Is Null AND
    --ST_Intersects(geom, wkt) AND
    [geom] Intersects [wkt] AND
    ST_GeometryType(wkt) = 'ST_Polygon'
) WITH DATA;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT x, y, z
	FROM C_30FZ1, bounds
	WHERE
    c = 2 and
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_Intersects(geom, Geometry(pa))
	Contains(geom, x, y)
) WITH DATA;

drop table polygons_;
create table polygons_ AS (
    SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, COALESCE(type,'transitie') as type, class, geom
    FROM plantcover
    UNION ALL
    SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, COALESCE(type,'transitie') as type, class, geom
    FROM bare
) WITH DATA;

drop table polygons_dump;
create table polygons_dump AS (
	SELECT parent as id, polygonWKB as geom
	FROM ST_DUMP((select geom, id from polygons_)) d
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT a.*
	FROM polygons_ a
    LEFT JOIN polygons_dump b
    ON a.id = b.id
) WITH DATA;

drop table polygonsz;
create table polygonsz AS (
	--SELECT id, fid, type, class, patch_to_geom(geom) as geom
	SELECT id, fid, type, class, ST_ExteriorRing(geom) as geom
    FROM polygons a
    LEFT JOIN pointcloud_ground b
    ON ST_Intersects(geom, x, y, z, 28992)
    GROUP BY id, fid, type, class, geom
) WITH DATA;
--insert into _edge_points SELECT cast(path as int) as path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ingeom)) d;

drop table edge_points;
create table edge_points AS (
    SELECT parent as polygon_id, cast(path as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, id from polygonsz)) d
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
	SELECT polygon_id as id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom  FROM line_z WHERE ST_IsValid(geom) group by id
) WITH DATA;

drop table triangles_b;
create table triangles_b as (
    select id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom from basepoints group by id
) WITH DATA;

drop table triangles;
create table triangles AS (
    --SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from triangles_b)) a
    SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from basepoints)) a
) WITH DATA;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(ST_SetSRID(b.geom, 28992), ST_SetSRID(a.geom, 28992))
	, bounds c
	WHERE
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id
) WITH DATA;

SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),4.0, 0) as geom FROM assign_triags p GROUP BY id, type;
