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
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_all AS (
	SELECT x, y, z, c
	FROM ahn3, bounds
	WHERE
    x between _west and _east and
    y between _south and _north and
    --ST_DWithin(geom, ST_MakePoint(x, y, z), 10)
    [geom] DWithin [x, y, z, 28992, 10]
),
pointcloud_ground AS (
	--SELECT PC_FilterEquals(pa,'classification',2) pa --ground points
    SELECT x, y, z
	FROM pointcloud_all
	WHERE
    c =2
),
footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.wkt, b.geom)) as geom,
	a.ogc_fid as id
	FROM bgt_scheiding a, bounds b
	WHERE
	bgt_type = 'kademuur' AND 
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
	[a.wkt] Intersects [b.geom] AND
	[ST_Centroid(a.wkt)] Intersects [b.geom]
),
papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		x, y, z,
		geom as footprint
	FROM footprints a
	LEFT JOIN pointcloud_ground b
    --ON (ST_Intersects(a.geom, Geometry(b.pa)))
    ON ([a.geom] Intersects [x, y, z, 28992])
),
papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a
	LEFT JOIN pointcloud_all b
    -- ON (ST_Intersects(a.geom, Geometry(b.pa)))
    ON [a.geom] Intersects [x, y, z, 28992]
    GROUP BY a.id
),
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints 
    WHERE
        [footprint] Intersects [x, y, z, 28992]
	--GROUP BY id, footprint
),
stats AS (
	SELECT  a.id, footprint, max(z) as max, min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
),
polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min)), 0,0,max-min) as geom
    FROM stats
)
SELECT id, 'kade' as typ, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons p;
