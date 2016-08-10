declare _west decimal(7,1);
declare _south decimal(7,1);
declare _east decimal(7,1);
declare _north decimal(7,1);
declare _segmentlength decimal(7,1);

set _west = 93468.9;
set _east = 93667.9;
set _south = 462610.7;
set _north = 462735.3;
set _segmentlength = 10;

with
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
),
bgt_wegdeel_light AS (
	--SELECT a.ogc_fid, 'road' AS class, a.bgt_functie as type, ST_Intersection(a.wkt,c.geom) as geom 
	SELECT a.ogc_fid, 'road' AS class, a.bgt_status as type, a.wkt as wkt, ST_Intersection(a.wkt,c.geom) as geom, col_xmin, col_xmax, col_ymin, col_ymax 
	FROM bgt_wegdeel a, bounds c
	WHERE 
    a.relatieveHoogteligging = 0 AND
	a.eindregistratie Is Null AND
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[geom] Intersects [a.wkt]
),
mainroads AS (
	SELECT a.ogc_fid, a.class, a.type, a.geom 
	FROM bgt_wegdeel_light a
	LEFT JOIN bgt_overbruggingsdeel b
	ON ([a.wkt] Intersects [b.wkt] AND [ST_buffer((b.wkt),1)] Contains [a.wkt])
	WHERE 
	--AND ST_CurveToLine(b.wkt) Is Null
	b.eindregistratie Is Null
	--AND [geom] Intersects [a.wkt]
),
auxroads AS (
	SELECT ogc_fid, 'road' AS class, bgt_functie as type, ST_Intersection(wkt,geom) as geom
	FROM bgt_ondersteunendwegdeel a, bounds b
	WHERE
    relatieveHoogteligging = 0 AND
	eindregistratie Is Null AND
	--AND ST_Intersects(geom, wkb_geometry)
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[geom] Intersects [wkt]
),
tunnels AS (
	SELECT ogc_fid, 'road' AS class, 'tunnel' as type, ST_Intersection(wkt,geom) as geom
	FROM bgt_tunneldeel a, bounds b
	WHERE
    eindregistratie Is Null AND
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[geom] Intersects [wkt]
),
pointcloud_ground AS (
	SELECT x, y, z
	--FROM ahn3, bounds
	FROM ahn3, bounds
	WHERE 
    --ST_Intersects(geom, x, y, z, 28992) AND
    --[geom] Intersects [x, y, z, 28992] AND
    c = 2 and
    x between _west and _east and
    y between _south and _north and
    --Contains(geom, x, y, z, 28992)
    [geom] Contains [x, y, z, 28992]
),
polygons_b AS (
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM mainroads
	UNION ALL
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM auxroads
	UNION ALL
	SELECT next value for "counter" as id, ogc_fid as fid, type, class, geom
	FROM tunnels
),
polygons_Dump AS (
    SELECT parent as id, next value for "counter" as polygon_id, ST_SetSRID(polygonWKB, 28992) as geom
    FROM ST_Dump((select geom, id from polygons_b)) d
),
polygons AS (
   select a.id, a.fid, a.type, a.class, b.polygon_id, b.geom
   FROM
   polygons_b a LEFT JOIN polygons_Dump b
   ON a.id = b.id
),
polygonsz AS (
	SELECT id, fid, polygon_id, type, class, geom
	FROM polygons a
	LEFT JOIN pointcloud_ground b
	--ON ST_Intersects(geom,Geometry(b.pa))
	ON [geom] Intersects [x, y, z, 28992]
	WHERE 
        --ST_IsValid(geom)
    [geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)]
	GROUP BY id, fid, polygon_id, type, class, geom
),
edge_points AS (
    --SELECT parent as id, cast(path as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, fid from polygonsz)) d
    --SELECT parent as id, cast((SUBSTRING(path, POSITION(',' IN path)+1)) as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, id from polygonsz)) d
    SELECT parent as polygon_id, cast((SUBSTRING(path, 0, POSITION(',' IN path)-1)) as int) as subpolygon_id, cast((SUBSTRING(path, POSITION(',' IN path)+1)) as int) as path, ST_SetSRID(pointg, 28992) as geom FROM ST_DumpPoints((select geom, polygon_id from polygonsz)) d
),
emptyz AS (
    SELECT polygon_id, subpolygon_id, a.path as path, a.geom as geom , b.z as z, ST_Distance(a.geom, x, y, z, 28992) as dist FROM edge_points a, pointcloud_ground b WHERE [a.geom] DWithin [x, y, z, 28992, 10]
),
ranktest AS (
    select polygon_id, subpolygon_id, path, geom, z, dist, RANK() over (PARTITION BY polygon_id, subpolygon_id, path order by polygon_id, subpolygon_id, path, dist ASC) as rank from emptyz
),
filledz AS (
    --select id, path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from ranktest where rank = 1 order by path
    select polygon_id, subpolygon_id, path, ST_MakePoint(ST_X(geom), ST_Y(geom), z) as geom from ranktest where rank = 1
),
line_z AS (
    SELECT polygon_id, subpolygon_id, ST_MakeLine(geom) as geom FROM filledz group by polygon_id, subpolygon_id
),
basepoints AS (
	SELECT polygon_id, subpolygon_id, ST_Triangulate2DZ(ST_Collect(geom),0) as geom FROM line_z
	WHERE 
    --ST_IsValid(geom)
    [geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)]
    GROUP BY polygon_id, subpolygon_id
),
triangles AS (
    SELECT parent as polygon_id, ST_SetSRID(ST_MakePolygon(ST_ExteriorRing( a.polygonWKB)), 28992) as geom FROM ST_Dump((select geom, polygon_id from basepoints)) a
),
assign_triags AS (
	SELECT 	a.*, b.id, b.type, b.class
	FROM triangles a
	--INNER JOIN polygons b
	, polygons b
	, bounds c
	WHERE 
    --ST_Intersects(ST_Centroid(b.geom), c.geom) AND
    [ST_Centroid(b.geom)] Intersects [c.geom] AND
	a.polygon_id = b.polygon_id AND
	--ON ST_Contains(b.geom, a.geom)
	[b.geom] Contains [a.geom] AND
    [a.geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)]

)

SELECT p.id as id, p.type as type, 'gray' as color, ST_AsX3D(ST_Collect(p.geom),5.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
