declare _west decimal(7,1);
declare _south decimal(7,1);
declare _east decimal(7,1);
declare _north decimal(7,1);
set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;

WITH
bounds AS (
    SELECT ST_MakeEnvelope(_west+10, _south+10, _east+10, _north+10, 28992) as geom
),
pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between _west and _east and
    y between _south and _north and
	Contains(geom, x, y)
	and c = 6
),
footprints AS (
	SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(wkt, 0.4),1)) as geom,
	a.ogc_fid as id,
	0 as bouwjaar
	FROM bgt_pand a, bounds b
	WHERE 1 = 1
	AND ST_Area(a.wkt) > 30
	AND [a.wkt] Intersects [b.geom]
	AND [ST_Centroid(a.wkt)] Intersects [b.geom]
	AND ST_IsValid(a.wkt)
),
stats_fast AS (
	SELECT
		footprints.id,
		bouwjaar,
		geom as footprint,
        max(z) as max,
        min(z) as min
	FROM footprints
    LEFT JOIN pointcloud ON
        ST_Intersects(geom, x, y, z, 28992)
	GROUP BY footprints.id, footprint, bouwjaar
),
polygons AS (
	SELECT
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min - 1)
			, 0,0,max-min -1)
		) as geom
        FROM stats_fast
)
SELECT id, 'building' as "type", 'red' as color, ST_AsX3D((p.geom), 4.0, 0) as geom FROM polygons p;
