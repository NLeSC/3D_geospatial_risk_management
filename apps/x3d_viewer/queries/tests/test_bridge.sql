declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
declare _segmentlength integer;
declare _zoom integer;

set _west = 93716.0;
set _east = 93916.0;
set _south = 463791.0;
set _north = 463991.0;
set _segmentlength = 10;
set _zoom = 10;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

DROP SEQUENCE "polygon_id";
CREATE SEQUENCE "polygon_id" AS INTEGER;

drop table bounds;
create table bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
) WITH DATA;

drop table pointcloud;
create table pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE 
        --ST_DWithin(geom, x, y, z, 28992, 10) --patches should be INSIDE bounds
          x between _west and _east and
          y between _south and _north and
        [geom] DWithin [x, y, z, 28992, 10] --patches should be INSIDE bounds
        and c = 26
) WITH DATA;

drop table footprints;
create table footprints AS (
	SELECT next value for "counter" as id, ogc_fid as fid, 'bridge' AS class, 'dek' AS type,
	--ST_CurveToLine(a.wkt) as geom
	a.wkt as geom
	FROM bgt_overbruggingsdeel a, bounds b
	WHERE 1 = 1
	AND typeoverbruggingsdeel = 'dek'
	--AND ST_Intersects(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992), b.geom)
	AND [a.wkt] Intersects [b.geom]
	--AND ST_Intersects(ST_Centroid(ST_SetSrid(ST_CurveToLine(a.wkb_geometry),28992)), b.geom)
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
) WITH DATA;

drop table bgt_wegdeel_light;
create table bgt_wegdeel_light AS (
	SELECT next value for "counter" as id, a.ogc_fid as fid, 'bridge' AS class, 
    a.bgt_functie as type, 
    a.wkt as geom
	FROM bgt_wegdeel a, bounds c
	WHERE a.relatieveHoogteligging > -1
	AND a.eindregistratie Is Null
	AND [c.geom] Intersects [a.wkt]
	AND [ST_Centroid(a.wkt)] Intersects [c.geom]
) WITH DATA;

drop table roads;
create table roads AS (
	SELECT id, fid, class, type, geom
	FROM bgt_wegdeel_light a
	LEFT JOIN bgt_overbruggingsdeel b
	--ON (St_Intersects((a.wkb_geometry), (b.wkb_geometry)) AND St_Contains(ST_buffer((b.wkb_geometry),1), (a.wkb_geometry)))
	ON ([a.geom] Intersects [b.wkt] AND [ST_buffer(b.wkt,1)] Contains [a.geom])
	WHERE
	b.eindregistratie Is Null
) WITH DATA;

drop table polygons;
create table polygons AS (
	SELECT * FROM footprints
	WHERE 
    --ST_GeometryType(geom) = 'ST_Polygon'
    [geom] IsType ['ST_Polygon']
	UNION ALL
	SELECT * FROM roads
	WHERE 
    --ST_GeometryType(geom) = 'ST_Polygon'
    [geom] IsType ['ST_Polygon']
) WITH DATA;

drop table rings_dump;
create table rings_dump AS (
    SELECT parent as fid, next value for "counter" as ring_id, cast(path as int) as path, polygonWKB as geom
    FROM ST_DumpRings((Select geom, fid from polygons)) d
) WITH DATA;

drop table rings;
create table rings as (
    select id, a.fid, ring_id, type, path, a.geom as geom0, b.geom
    from polygons a LEFT JOIN rings_dump b on a.fid = b.fid
) WITH DATA;

drop table edge_points_dump;
create table edge_points_dump AS (
	SELECT parent as ring_id, next value for "counter" as ring_point_id, pointG as geom, path
	FROM ST_DumpPoints( (select geom, ring_id from rings)) d
) WITH DATA;

drop table edge_points;
create table edge_points AS (
	SELECT id, a.fid, a.ring_id, ring_point_id, type, geom0, a.path as ring, ST_SetSRID(b.geom, 28992) as geom, b.path
	FROM rings a LEFT JOIN edge_points_dump b ON a.ring_id = b.ring_id
) WITH DATA;

drop table edge_points_patch;
create table edge_points_patch AS ( --get closest patch to every vertex
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
	ON [a.geom] Intersects [x, y, z, 28992] OR [a.geom] DWITHIN [x, y, z, 28992, 10]
	--ON [a.geom] DWITHIN [x, y, z, 28992, 100]
) WITH DATA;

drop table emptyz;
create table emptyz AS (
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
) WITH DATA;

drop table filter;
create table filter AS (
	SELECT
		a.id, a.fid, a.ring_id, ring_point_id, a.type, a.path, a.ring, a.geom, z
	FROM emptyz a
    WHERE
        z between avg-0.2 and avg+0.2
) WITH DATA;

drop table filledz;
create table filledz AS (
	--SELECT id, fid, ring_id, ring_point_id, type, path, ring, ST_Translate(St_Force3D(geom), 0,0,avg(z)) as geom
	SELECT id, fid, ring_id, ring_point_id, type, path, ring, ST_Translate(St_Force3D(geom), 0,0,2) as geom
	FROM filter
	GROUP BY id, fid, ring_id, ring_point_id, type, path, ring, geom
	ORDER BY id, ring_id,ring_point_id, ring, path
) WITH DATA;

drop table allrings;
create table allrings AS (
	--SELECT id, fid, type, ring, ST_AddPoint(ST_MakeLine(geom), First(geom)) as geom
	SELECT id, fid, ring_id, type, ring, ST_MakeLine(geom) as geom
	FROM filledz
	GROUP BY id,fid, ring_id, type, ring
) WITH DATA;

--TODO: Here we should use existent functions
drop table outerrings;
create table outerrings AS (
	--SELECT id, fid, type, ring, ST_AddPoint(geom, ST_StartPoint(geom), ST_NumPoints(geom)) as geom --The Point is added at the beginning, not at the end.
	SELECT id, fid, type, ring, geom --ST_AddPoint(geom, ST_StartPoint(geom), ST_NumPoints(geom)) as geom
	FROM allrings
	WHERE ring = 1
) WITH DATA;

drop table innerrings;
create table innerrings AS (
	--SELECT id, fid, type, St_Accum(geom) as arr
	SELECT id, fid, ring_id, type, geom as arr
	FROM allrings
	WHERE ring > 1  
	--GROUP BY id, fid, type
) WITH DATA;

drop table polygonsz;
create table polygonsz AS (
	--SELECT a.id, a.fid, a.type, COALESCE(ST_MakePolygon(a.geom, b.arr),ST_MakePolygon(a.geom)) as geom --We do not have MakePolygon outer ring and list of inner rings.
	SELECT a.id, a.fid, ring_id, a.type, ST_Polygon(a.geom, 28992) as geom
	FROM outerrings a
	LEFT JOIN innerrings b ON a.id = b.id
) WITH DATA;

drop table terrain_polygons;
create table terrain_polygons AS (
    SELECT * FROM polygonsz
) WITH DATA;

drop table all_points;
create table all_points AS ( -- get pts in every boundary
	SELECT t.id, ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom
	FROM pointcloud, terrain_polygons t
	WHERE 
        --ST_Intersects(geom, geometry(pa))
        [geom] Intersects [x, y, z, 28992]
) WITH DATA;

drop table innerpoints;
create table innerpoints AS (
	SELECT a.id, a.geom
	FROM all_points a, terrain_polygons b
	--INNER JOIN terrain_polygons b
	--ON a.id = b.id
    WHERE
	a.id = b.id AND 
   -- ST_Intersects(a.geom, b.geom)
   [a.geom] Intersects [b.geom] AND
	--AND Not ST_DWithin(a.geom, ST_ExteriorRing(b.geom),1)
	--Not [a.geom] DWithin [ST_ExteriorRing(b.geom),1]
	Not [a.geom] DWithin [ST_ExteriorRing(b.geom),1]
	AND rand() < (0.1 * _zoom)
	AND (b.type <> 'road')
) WITH DATA;

drop table basepoints;
create table basepoints AS (
	--SELECT id, geom FROM innerpoints
	--UNION
	SELECT id,geom FROM polygonsz
	WHERE 
    --ST_IsValid(geom)
    [geom] IsValidD [ST_MakePoint(1.0, 1.0, 1.0)] --ST_Buffer to avoid: !ERROR: Ring Self-intersection at or near point
) WITH DATA;

drop table triangles_a;
create table triangles_a AS (
	SELECT
		id, ST_Triangulate2DZ(ST_Collect(a.geom), 0) as geom
	FROM basepoints a
	GROUP BY id
) WITH DATA;

drop table triangles;
create table triangles AS (
	SELECT
		parent as id,
		ST_MakePolygon(
			ST_ExteriorRing(polygonWKB)) as geom
	FROM ST_DUMP((select geom, id from triangles_a)) a
) WITH DATA;

drop table assign_triags;
create table assign_triags AS (
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
) WITH DATA;

SELECT p.id AS id, p.type as type, ST_AsX3D(ST_Collect(p.geom),3.0, 0) as geom FROM assign_triags p GROUP BY p.id, p.type;
