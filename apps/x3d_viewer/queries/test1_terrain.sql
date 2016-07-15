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

DROP ALL FUNCTION patch_to_geom;
CREATE FUNCTION patch_to_geom(ingeom geometry) RETURNS geometry
BEGIN
    Declare table _edge_points( path int, geom geometry);
    Declare table _emptyz(path int, geom geometry, z decimal(9,3), dist double);
    Declare table _ranktest(path int, geom geometry, z decimal(9,3), dist double, rank int);
    Declare table _filledz( path int, geom geometry);
    Declare table _line_z(geom geometry);

    insert into _edge_points SELECT cast(path as int) as path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ingeom)) d;
    insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist FROM _edge_points a, pointcloud_ground b;
    insert into _ranktest select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) as rank from _emptyz;
    insert into _filledz select path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from _ranktest where rank = 1 order by path;
    insert into _line_z SELECT ST_MakeLine(geom) as geom FROM _filledz;
    return
        select ST_Polygon(geom, 28992) from _line_z;
END;

DROP SEQUENCE "polygon_id";
CREATE SEQUENCE "polygon_id" AS INTEGER;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

WITH
triangles_b as (
    select geom, polygon_id from basepoints
),
triangles AS (
    SELECT parent as polygon_id, a.polygonWKB as geom FROM ST_Dump((select geom, polygon_id from triangles_b)) a
),
assign_triags AS (
	SELECT a.geom FROM triangles a, triangles_b d WHERE a.polygon_id = d.polygon_id
)

SELECT ST_AsX3D(p.geom,4.0, 0) as geom FROM assign_triags p;
