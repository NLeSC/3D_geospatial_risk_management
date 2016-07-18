declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
declare _segmentlength integer;

set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;
set _segmentlength = 10;

WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_ground AS (
	SELECT
        ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, z
	FROM
        C_30FZ1, bounds
	WHERE
        --ST_DWithin(geom, Geometry(pa),10)
        x between 93816.0 and 93916.0 and
        y between 463891.0 and 463991.0 and
    	Contains(geom, x, y) and
        c = 1 and
        r = 1 and
        i > 150
),
--pointcloud_all AS (
--	SELECT
--        x, y, z
--	FROM
--        C_30FZ1, bounds
--	WHERE
--        ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992),10)
--),
footprints AS (
	SELECT
        ST_Force3D(ST_Intersection(a.wkt, b.geom)) as geom,
    	a.ogc_fid as id
	FROM bgt_kunstwerkdeel a, bounds b
	WHERE
	    (plus_type = 'steiger') AND
	    ST_Intersects(a.wkt, b.geom)
),
papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		b.geom as pt,
        z,
		a.geom as footprint
	FROM footprints a
	LEFT JOIN
    pointcloud_ground b ON
    ST_Intersects(a.geom, b.geom)
),
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, pt as geom, footprint, min(z) as min
	FROM papoints
    WHERE
        ST_Intersects(footprint, pt)
	GROUP BY id, geom, footprint
),
polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min+0.4)),0,0,0.2) as geom FROM footprintpatch
)
SELECT id, 'steiger' as type, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons p;
