declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;


WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_ground AS (
	--SELECT PC_FilterEquals(pa,'classification',2) pa --ground points
    SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_DWithin(geom, ST_MakePoint(x, y, z), 10)
    Contains(geom, x, y)
    and c =2
),
pointcloud_all AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_DWithin(geom, ST_MakePoint(x, y, z), 10)
    Contains(geom, x, y)
),
footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.geom, b.geom)) as geom,
	a.ogc_fid as id
	FROM bgt_polygons a, bounds b
	WHERE 1 = 1
	--AND (type = 'kademuur' OR class = 'border')
	AND ST_Intersects(a.geom, b.geom)
	AND ST_Intersects(ST_Centroid(a.geom), b.geom)
),
papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		x, y, z,
		geom as footprint
	FROM footprints a, pointcloud_ground b
	--LEFT JOIN pointcloud_ground b ON (ST_Intersects(a.geom, Geometry(b.pa)))
	where
        ST_Intersects(a.geom, ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992))
),
papatch AS (
	SELECT
		a.id, min(z) as min
	FROM footprints a, pointcloud_all b
	--LEFT JOIN pointcloud_all b ON (ST_Intersects(a.geom, Geometry(b.pa)))
	WHERE 
        ST_Intersects(a.geom,  ST_SetSRID(ST_MakePoint(b.x, b.y, b.z), 28992))
	GROUP BY a.id
),
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, x, y, z, footprint
	FROM papoints 
    WHERE
        ST_Intersects(footprint,  ST_SetSRID(ST_MakePoint(x, y, z), 28992))
	--GROUP BY id, footprint
),
stats AS (
	SELECT  a.id, footprint, max(z) as max, min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
	GROUP BY a.id, footprint, min
),
polygons_kade AS (
	--SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min)), 0,0,max-min) as geom
	SELECT id, ST_Tesselate(ST_Translate(footprint,0,0, min)) as geom
    FROM stats
)
SELECT id, 'kade' as typ, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons_kade p;
