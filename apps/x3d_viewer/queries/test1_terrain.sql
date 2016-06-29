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

declare _geom2 string;
set _geom2 = 'POLYGON ((93910.602 463934.263, 93914.44 463934.856, 93907.227 463933.742, 93910.602 463934.263))';

select ST_AddPoint(ST_ExteriorRing(ST_SETSRID(ST_GeometryFromText(_geom2),28992)), ST_StartPoint(ST_ExteriorRing(ST_SETSRID(ST_GeometryFromText(_geom2),28992))), 2);

select patch_to_geom(ST_SETSRID(ST_GeometryFromText(_geom2),28992));

drop table bounds;
create table bounds AS (SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992), _segmentlength) as geom) with data;

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
) with data;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

drop table terrain_;
create table terrain_ AS (
    SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, 'unkown' as typ, class, a.geom as a_geom, b.geom as b_geom
    FROM bgt_polygons a, bounds b
    WHERE
    type <> 'water' and
    class <> 'water' and
    type <> 'kademuur' and
    [a.geom] Intersects [b.geom]
) with data;

drop table terrain_b;
create table terrain_b AS (
	SELECT id, fid, typ, class, ST_Intersection(a_geom, b_geom) as ab_geom
	FROM terrain_
) with data;

drop table terrain_dump;
create table terrain_dump AS (
	SELECT parent as id, polygonWKB as geom
	--FROM ST_Dump((select ab_geom from terrain_), (select id from terrain_)) d
	FROM ST_Dump((select ab_geom, id from terrain_b)) d
) with data;


drop table polygons;
create table polygons AS (
	SELECT t.id, fid, 'unknown' as typ, class, d.geom
	FROM terrain_b t, terrain_dump d
    where
    t.id = d.id and
    ST_GeometryType(d.geom) = 'ST_Polygon'
) with data;

DROP FUNCTION patch_to_geom;
CREATE FUNCTION patch_to_geom(ingeom geometry) RETURNS geometry
BEGIN
    Declare table _papoints(x decimal(9,3), y decimal(9,3), z decimal(9,3));
    Declare table _edge_points( path string, geom geometry);
    Declare table _emptyz(path string, geom geometry, z decimal(9,3), dist double);
    Declare table _ranktest(path string, geom geometry, z decimal(9,3), dist double, rank int);
    Declare table _filledz( path string, geom geometry);
    Declare table _line_z(geom geometry);

    insert into _papoints SELECT x, y, z from pointcloud_ground;
    insert into _edge_points SELECT path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ingeom)) d;
    --insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MAkePoint(x, y), 28992)) as dist FROM _edge_points a, _papoints b;
    insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, ST_MAkePoint(x, y, z)) as dist FROM _edge_points a, _papoints b;
    insert into _ranktest select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) from _emptyz;
    --insert into _filledz select path, ST_SetSRID(ST_MakePoint(ST_X(geom), ST_Y(geom), z), 28992) as geom from _ranktest where rank = 1 order by path;
    insert into _filledz select path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from _ranktest where rank = 1 order by path;
    insert into _line_z SELECT ST_MakeLine(geom) as geom FROM _filledz;
    return
        --select ST_Polygon(geom, 28992) from _line_z;
        --select ST_BdMPolyFromText(ST_AsText(geom), 28992) from _line_z;
        select geom from _line_z;
END;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, fid, typ, class, patch_to_geom(geom) as geom FROM polygons a, pointcloud_ground b WHERE Contains(geom, x, y) GROUP BY id, fid, typ, class, geom
) with data;

drop table basepoints;
create table basepoints AS (
	SELECT id,geom FROM polygonsz WHERE ST_IsValid(geom)
    ) with data;

drop table triangles;
create table triangles AS (
	SELECT parent, ST_MakePolygon( ST_ExteriorRing( a.polygonWKB)) as geom
	FROM ST_Dump((select ST_Triangulate2DZ(ST_Collect(geom)), id from basepoints)) a
	GROUP BY parent
) with data;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id
) with data;

--SELECT _south::text || _west::text || p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),3) as geom FROM assign_triags p GROUP BY id, type;
SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),3) as geom FROM assign_triags p GROUP BY id, type;
