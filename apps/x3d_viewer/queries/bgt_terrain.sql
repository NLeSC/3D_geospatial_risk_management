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

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

WITH
bounds AS (
    SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992), _segmentlength) as geom
),
plantcover AS (
	SELECT ogc_fid, 'plantcover' AS class, bgt_fysiekvoorkomen as type, St_Intersection(wkt, geom) as geom 
	FROM bgt_begroeidterreindeel, bounds
	WHERE 
    eindregistratie Is Null AND
    --ST_Intersects(geom, wkt) AND
    [geom] Intersects [wkt] AND
    ST_GeometryType(wkt) = 'ST_Polygon'
),
bare AS (
	SELECT ogc_fid, 'bare' AS class, bgt_fysiekVoorkomen as type, St_Intersection(wkt, geom) as geom
	FROM bgt_onbegroeidterreindeel, bounds
	WHERE
    eindregistratie Is Null AND
    --ST_Intersects(geom, wkt) AND
    [geom] Intersects [wkt] AND
    ST_GeometryType(wkt) = 'ST_Polygon'
),
pointcloud_ground AS (
	SELECT x, y, z
	FROM C_30FZ1, bounds
	WHERE
    c = 2 and
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_Intersects(geom, Geometry(pa))
	Contains(geom, x, y)
),
polygons_ AS (
    SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, COALESCE(type,'transitie') as type, class, geom
    FROM plantcover
    UNION ALL
    SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, COALESCE(type,'transitie') as type, class, geom
    FROM bare
),
polygons_dump AS (
	SELECT parent as id, polygonWKB as geom
	FROM ST_DUMP((select geom, id from polygons_)) d
),
polygons AS (
	SELECT a.*
	FROM polygons_ a
    LEFT JOIN polygons_dump b
    ON a.id = b.id
),
polygonsz AS (
	SELECT id, fid, type, class, patch_to_geom(geom) as geom
    FROM polygons a
    LEFT JOIN pointcloud_ground b
    ON ST_Intersects(geom, x, y, z, 28992)
    GROUP BY id, fid, type, class, geom
),
basepoints AS (
	SELECT id, geom FROM polygonsz WHERE ST_IsValid(geom)
),
triangles_b as (
    select id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom from basepoints group by id
),
triangles AS (
    SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from triangles_b)) a
),
assign_triags AS (
	SELECT 	a.*, d.id, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(ST_SetSRID(b.geom, 28992), ST_SetSRID(a.geom, 28992))
	, bounds c, triangles_b d
	WHERE
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id and a.id = d.id
)

SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),4.0, 0) as geom FROM assign_triags p GROUP BY id, type;
