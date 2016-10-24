
with
bounds AS (
    SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between _west and _east and
    y between _south and _north and
	--Contains(geom, x, y, z, 28992)
	[ST_SetSRID(geom, 28992)] Contains [x, y, z, 28992]
	and c = 6
),
footprints AS (
	SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(wkt, 0.4),1)) as geom,
	a.ogc_fig as id,
	0 as bouwjaar
	FROM bgt_pand a, bounds b
	WHERE --1 = 1
	--AND ST_Area(a.wkt) > 30
	--AND
    col_area > 30.0 AND 
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
    [ST_SetSRID(a.wkt, 28992)] Intersects [ST_SetSRID(b.geom, 28992)]
	AND [ST_SetSRID(ST_Centroid(a.wkt), 28992)] Intersects [ST_SetSRID(b.geom, 28992)]
	--AND ST_IsValid(a.wkt)
	--AND [a.wkt] IsValidD [ST_MakePoint(1.0,1.0,1.0)]
    AND col_isvalid = true
),
stats_fast AS (
	SELECT
		footprints.id,
		bouwjaar,
		geom as footprint,
        avg(z) as max,
        min(z) as min
	FROM footprints
    LEFT JOIN pointcloud ON
        --ST_Intersects(geom, x, y, z, 28992)
        [ST_SetSRID(geom, 28992)] Intersects [x, y, z, 28992]
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
