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
	FROM ahn3, bounds
	--FROM ahn3, bounds
	WHERE
    c = 2 and
    x between _west and _east and
    y between _south and _north and
    --ST_Intersects(geom, Geometry(pa))
	Contains(geom, x, y, z, 28992)
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
	--SELECT id, fid, type, class, patch_to_geom(geom) as geom
	SELECT id, fid, type, class, ST_ExteriorRing(geom) as geom
    FROM polygons a
    LEFT JOIN pointcloud_ground b
    ON ST_Intersects(geom, x, y, z, 28992)
    GROUP BY id, fid, type, class, geom
),
--insert into _edge_points SELECT cast(path as int) as path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ingeom)) d;
edge_points AS (
    SELECT parent as polygon_id, cast(path as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, id from polygonsz)) d
),
--insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist FROM _edge_points a, pointcloud_ground b;
emptyz AS (
    --SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist FROM edge_points a, pointcloud_ground b WHERE ST_DWithin(a.geom, x, y, z, 28992, 10)
    --SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, x, y, z, 28992) as dist FROM edge_points a, pointcloud_ground b WHERE ST_DWithin(a.geom, x, y, z, 28992, 10)
    SELECT polygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, x, y, z, 28992) as dist FROM edge_points a, pointcloud_ground b WHERE [a.geom] DWithin [x, y, z, 28992, 10]
),
--insert into _ranktest select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) as rank from _emptyz;
ranktest AS (
    select polygon_id, path, geom, z, dist, RANK() over (PARTITION BY polygon_id, path order by polygon_id, path, dist ASC) as rank from emptyz
),
--insert into _filledz select path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from _ranktest where rank = 1 order by path;
filledz AS (
    select polygon_id, path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from ranktest where rank = 1
),
--insert into _line_z SELECT ST_MakeLine(geom) as geom FROM _filledz;
line_z AS (
    SELECT polygon_id, ST_MakeLine(geom) as geom FROM filledz group by polygon_id
),
basepoints AS (
	--SELECT polygon_id as id, geom FROM line_z WHERE ST_IsValid(geom)
	SELECT polygon_id as id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom FROM line_z WHERE ST_IsValid(geom) group by id
),
--triangles_b as (
--    select id, ST_Triangulate2DZ(ST_Collect(geom), 0) as geom from basepoints group by id
--),
triangles AS (
    --SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from triangles_b)) a
    SELECT parent as id, ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)) as geom FROM ST_Dump((select geom, id from basepoints)) a
),
assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(ST_SetSRID(b.geom, 28992), ST_SetSRID(a.geom, 28992))
	, bounds c
	WHERE
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id
)

SELECT p.id as id, p.type as type, ST_AsX3D(ST_Collect(p.geom),4.0, 0) as geom FROM assign_triags p GROUP BY id, type;
