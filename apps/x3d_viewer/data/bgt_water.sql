declare _west decimal(7,1);
declare _south decimal(7,1);
declare _east decimal(7,1);
declare _north decimal(7,1);
declare _segmentlength decimal(7,1);

set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;
set _segmentlength = 10;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

with
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
),
pointcloud_water AS (
	SELECT
        x, y, z
	FROM
        --ahn3, bounds
        ahn3, bounds
	WHERE
        --ST_Intersects(geom, Geometry(pa))
        x between _west and _east and
        y between _south and _north and
    	Contains(geom, x, y, z, 28992) and
    	--[geom] Contains [x, y, z, 28992] and
        c = 9
),
terrain_ AS (
	SELECT NEXT VALUE FOR "counter" as id, ogc_fid as fid, plus_type as typ, 'water' as class, ST_Intersection(a.wkt, b.geom) as geom FROM  bgt_waterdeel a, bounds b WHERE [a.wkt] Intersects [b.geom]
),
terrain_Dump AS (
	SELECT parent as id, polygonWKB as geom FROM ST_Dump((select geom, id from terrain_)) a
),
terrain AS (
	SELECT a.id, a.fid, a.typ, a.class, b.geom FROM terrain_ a LEFT JOIN terrain_Dump b ON a.id = b.id
),
polygons AS (
	SELECT * FROM terrain
    WHERE
    --ST_GeometryType(geom) = 'ST_Polygon'
    [geom] IsType ['ST_Polygon']
),
polygonsz AS (
	SELECT a.id, a.fid, a.typ, a.class, ST_Translate(ST_Force3D(a.geom), 0,0,0) as geom --fixed level
	FROM polygons a
	--GROUP BY a.id, a.fid, a.typ, a.class, a.geom
),
basepoints AS (
	SELECT id, fid, geom FROM polygonsz
    WHERE
    --ST_IsValid(geom)
    [geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)]
),
triangles_b AS (
    select id, fid, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom from basepoints group by id, fid
),
triangles_Dump AS (
    SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from triangles_b)) a
),
triangles AS (
    SELECT a.id, a.fid, b.geom
    FROM triangles_b a
    LEFT JOIN triangles_Dump b
    ON a.id = b.id
),
assign_triags AS (
	SELECT 	a.*, b.typ, b.class
	FROM triangles a
	INNER JOIN polygons b
	--ON ST_Contains(ST_SetSRID(b.geom, 28992), ST_SetSRID(a.geom, 28992))
	ON [ST_SetSRID(b.geom, 28992)] Contains [ST_SetSRID(a.geom, 28992)]
	, bounds c
    WHERE
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id
)
SELECT p.id AS id, 'water' as type, ST_AsX3D(ST_Collect(p.geom),4.0, 0) as geom FROM assign_triags p GROUP BY id, type;
