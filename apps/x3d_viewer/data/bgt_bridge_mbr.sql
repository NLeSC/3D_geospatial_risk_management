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

with
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
),
pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE 
    x between _west and _east and
    y between _south and _north and
    [geom] DWithin [x, y, z, 28992, 10] --patches should be INSIDE bounds
    and c = 26
),
footprints AS (
	SELECT next value for "counter" as id, ogc_fid as fid, 'bridge' AS class, 'dek' AS type,
	--ST_CurveToLine(a.wkt) as geom
	a.wkt as geom
	FROM bgt_overbruggingsdeel a, bounds b
	WHERE 1 = 1
    AND (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    )
	AND typeoverbruggingsdeel = 'dek'
	--AND ST_Intersects(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992), b.geom)
	AND [a.wkt] Intersects [b.geom]
	--AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), b.geom)
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
),
wegdeel_light AS (
	SELECT next value for "counter" as id, a.ogc_fid as fid, 'bridge' AS class, 
    a.bgt_functie as type, 
    a.wkt as geom
	FROM bgt_wegdeel a, bounds c
	WHERE a.relatieveHoogteligging > -1
    AND (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    )
	AND a.eindregistratie Is Null
	AND [c.geom] Intersects [a.wkt]
	AND [ST_Centroid(a.wkt)] Intersects [c.geom]
),
roads AS (
	SELECT id, fid, class, type, geom
	FROM wegdeel_light a
	LEFT JOIN bgt_overbruggingsdeel b
	--ON (St_Intersects((a.wkb_geometry), (b.wkb_geometry)) AND St_Contains(ST_buffer((b.wkb_geometry),1), (a.wkb_geometry)))
	ON ([a.geom] Intersects [b.wkt] AND [ST_buffer(b.wkt,1)] Contains [a.geom])
	WHERE
	b.eindregistratie Is Null
),
polygons AS (
	SELECT * FROM footprints
	WHERE 
    --ST_GeometryType(geom) = 'ST_Polygon'
    [geom] IsType ['ST_Polygon']
	UNION ALL
	SELECT * FROM roads
	WHERE 
    --ST_GeometryType(geom) = 'ST_Polygon'
    [geom] IsType ['ST_Polygon']
),
rings_dump AS (
    SELECT parent as fid, next value for "counter" as ring_id, cast(path as int) as path, polygonWKB as geom
    FROM ST_DumpRings((Select geom, fid from polygons)) d
),
rings AS (
    select id, a.fid, ring_id, type, path, a.geom as geom0, b.geom
    from polygons a LEFT JOIN rings_dump b on a.fid = b.fid
),
edge_points_dump AS (
	SELECT parent as ring_id, next value for "counter" as ring_point_id, pointG as geom, path
	FROM ST_DumpPoints( (select geom, ring_id from rings)) d
),
edge_points AS (
	SELECT id, a.fid, a.ring_id, ring_point_id, type, geom0, a.path as ring, ST_SetSRID(b.geom, 28992) as geom, b.path
	FROM rings a LEFT JOIN edge_points_dump b ON a.ring_id = b.ring_id
),
edge_points_patch AS ( --get closest patch to every vertex
	SELECT a.id, a.fid, a.ring_id, ring_point_id, a.type, a.geom0, a.path, a.ring, a.geom, --find closes patch to point
    x, y, z
	--PC_Explode(COALESCE(b.pa, --if not intersection, then get the closest one
	--	(
	--	SELECT x, y, z FROM pointcloud b
	--	ORDER BY a.geom <#> Geometry(b.pa)
	--	LIMIT 1
	--	)
	--)) pt
	FROM edge_points a LEFT JOIN pointcloud b
	--ON ST_Intersects(a.geom, geometry(pa))
	--ON (ST_Intersects(a.geom, x, y, z, 28992) OR ST_DWITHIN(a.geom, x, y, z, 28992, 10))
	ON [a.geom] Intersects [x, y, z, 28992] OR [a.geom] DWITHIN [x, y, z, 28992, 100]
	--ON [a.geom] DWITHIN [x, y, z, 28992, 100]
),
emptyz AS (
	SELECT
		a.id, a.fid, a.ring_id, ring_point_id, a.type, a.path, a.ring, a.geom,
        z,
		min(z) as min,
		max(z) as max,
		avg(z) as avg
	FROM edge_points_patch a
	WHERE 
        --ST_Intersects(geom0, Geometry(pt))
        --ST_Intersects(geom0, x, y, z, 28992)
        [geom0] Intersects [x, y, z, 28992]
	GROUP BY a.id, a.fid, a.ring_id, ring_point_id, a.type, a.path, a.ring, a.geom, z
),
filter AS (
	SELECT
		a.id, a.fid, a.ring_id, ring_point_id, a.type, a.path, a.ring, a.geom, z
	FROM emptyz a
    WHERE
        z between avg-0.2 and avg+0.2
),
filledz AS (
	SELECT id, fid, ring_id, ring_point_id, type, path, ring, ST_Translate(St_Force3D(geom), 0,0,avg(z)) as geom
	FROM filter
	GROUP BY id, fid, ring_id, ring_point_id, type, path, ring, geom
	--ORDER BY id, ring_id,ring_point_id, ring, path
),
allrings AS (
	--SELECT id, fid, type, ring, ST_AddPoint(ST_MakeLine(geom), First(geom)) as geom
	SELECT id, fid, ring_id, type, ring, ST_MakeLine(geom) as geom
	FROM filledz
	GROUP BY id,fid, ring_id, type, ring
),
outerrings AS (
	--SELECT id, fid, type, ring, ST_AddPoint(geom, ST_StartPoint(geom), ST_NumPoints(geom)) as geom --The Point is added at the beginning, not at the end.
	SELECT id, fid, type, ring, geom --ST_AddPoint(geom, ST_StartPoint(geom), ST_NumPoints(geom)) as geom
	FROM allrings
	WHERE ring = 1
),
innerrings AS (
	--SELECT id, fid, type, St_Accum(geom) as arr
	SELECT id, fid, ring_id, type, geom as arr
	FROM allrings
	WHERE ring > 1  
	--GROUP BY id, fid, type
),
polygonsz AS (
	--SELECT a.id, a.fid, a.type, COALESCE(ST_MakePolygon(a.geom, b.arr),ST_MakePolygon(a.geom)) as geom --We do not have MakePolygon outer ring and list of inner rings.
	SELECT a.id, a.fid, ring_id, a.type, ST_Polygon(a.geom, 28992) as geom
	FROM outerrings a
	LEFT JOIN innerrings b ON a.id = b.id
),
terrain_polygons AS (
    SELECT * FROM polygonsz
),
all_points AS ( -- get pts in every boundary
	SELECT t.id, ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom
	FROM pointcloud, terrain_polygons t
	WHERE 
        --ST_Intersects(geom, geometry(pa))
        [geom] Intersects [x, y, z, 28992]
),
basepoints AS (
	--SELECT id, geom FROM innerpoints
	--UNION
	SELECT id,geom FROM polygonsz
	WHERE 
    --ST_IsValid(geom)
    [geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)] --ST_Buffer to avoid: !ERROR: Ring Self-intersection at or near point
),
triangles_a AS (
	SELECT
		id, ST_Triangulate2DZ(ST_Collect(a.geom), 0) as geom
	FROM basepoints a
	GROUP BY id
),
triangles AS (
	SELECT
		parent as id,
		ST_MakePolygon(
			ST_ExteriorRing(polygonWKB)) as geom
	FROM ST_DUMP((select geom, id from triangles_a)) a
),assign_triags AS (
	SELECT 	a.id,
		CASE
			WHEN b.type <> 'dek' THEN ST_Translate(a.geom, 0,0,1)
			ELSE a.geom
		END as geom, b.type
	FROM triangles a
	INNER JOIN polygons b
	ON [ST_SetSRID(b.geom, 28992)] Contains [ST_SetSRID(a.geom, 28992)]
	,bounds c
	WHERE 
    --ST_Intersects(ST_Centroid(b.geom), c.geom)
    [ST_Centroid(b.geom)] Intersects [c.geom]
	AND a.id = b.id
)
SELECT p.id AS id, p.type as type, ST_AsX3D(ST_Collect(p.geom),3.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
