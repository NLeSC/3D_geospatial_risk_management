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
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_ground AS (
	SELECT
        ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, z
	FROM
        --ahn3, bounds
        ahn3, bounds
	WHERE
        --ST_DWithin(geom, Geometry(pa),10)
        [geom] DWithin [x, y, z, 28992,10] and
        x between _west and _east and
        y between _south and _north and
        c = 1 and
        r = 1 and
        i > 150
),
footprints AS (
	SELECT
        ST_Force3D(ST_Intersection(a.wkt, b.geom)) as geom,
    	a.ogc_fid as id
	FROM bgt_kunstwerkdeel a, bounds b
	WHERE
	    (plus_type = 'steiger') AND
	    [a.wkt] Intersects [b.geom]
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
    [a.geom] Intersects [b.geom]
),
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, pt as geom, footprint, min(z) as min
	FROM papoints
    WHERE
        [footprint] Intersects [pt]
	GROUP BY id, geom, footprint
),
polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min+0.4)),0,0,0.2) as geom FROM footprintpatch
)
SELECT id, 'steiger' as type, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons p;
