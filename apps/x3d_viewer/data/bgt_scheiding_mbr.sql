

 with
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_building AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between _west and _east and
    y between _south and _north and
    --ST_DWithin(geom, ST_MakePoint(x, y, z),10) --patches should be INSIDE bounds
    [geom] DWithin [x, y, z, 28992, 10] --patches should be INSIDE bounds
    --Contains(geom, x, y, z, 28992)
    --[geom] Contains [x, y, z, 28992]
    and c = 1
    and r = 1
    and i > 150
),
bgt_scheiding_light AS (
	SELECT a.ogc_fig as id, 'border' as class, a.bgt_type as type,
    --ST_Force3D(ST_CurveToLine(a.wkt)) as geom
    ST_Force3D(a.wkt) as geom
	FROM bgt_scheiding a, bounds c
	WHERE
    a.relatieveHoogteligging > -1 AND
	bgt_type = 'muur' AND
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[a.wkt] Intersects [c.geom] AND
	[ST_Centroid(a.wkt)] Intersects [c.geom]
),
footprints AS (
	SELECT a.id, a.class, a.type, a.geom
	FROM bgt_scheiding_light a
    LEFT JOIN bgt_overbruggingsdeel b
    --ON ([a.geom] Intersects [b.wkt]) AND St_Contains(ST_buffer((b.wkt),1), (a.geom))
    ON ([a.geom] Intersects [b.wkt]) AND [ST_buffer((b.wkt),1)] Contains [a.geom]
	WHERE
    (b.wkt) Is Null
),
papoints AS ( --get points from intersecting patches
	SELECT a.id, x, y, z, geom as footprint
	FROM footprints a
	LEFT JOIN pointcloud_building b
    --ON (ST_Intersects(a.geom, b.x, b.y, b.z, 28992))
    ON [a.geom] Intersects [b.x, b.y, b.z, 28992]
),
papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a
	LEFT JOIN pointcloud_building b
    --ON (ST_Intersects(a.geom, b.x, b.y, b.z, 28992))
    ON [a.geom] Intersects [b.x, b.y, b.z, 28992]
	GROUP BY a.id
),
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints
    WHERE
    --ST_Intersects(footprint, ST_SetSRID(ST_MakePoint(x, y, z), 28992))
    [footprint] Intersects [x, y, z, 28992]
	--GROUP BY id, footprint
),
stats AS (
	SELECT  a.id, footprint,
		avg(z) as max,
		min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
),
polygons AS (
	SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min), 0,0,max-min) as geom
    FROM stats
	--SELECT id, ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
)
SELECT id,'building' as type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom, 4.0, 0) as  geom FROM polygons;
