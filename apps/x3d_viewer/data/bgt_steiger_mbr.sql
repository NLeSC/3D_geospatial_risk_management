

with
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_ground AS (
	SELECT
        --ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, z
        x, y, z
	FROM
        ahn3, bounds
	WHERE
        x between _west and _east and
        y between _south and _north and
        --ST_DWithin(geom, Geometry(pa),10)
        [geom] DWithin [x, y, z, 28992,50] and
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
	    (bgt_type = 'steiger') AND
        (NOT
        ((a.col_ymax < _south) OR
        (a.col_ymin  > _north) OR
        (a.col_xmax  < _west) OR
        (a.col_xmin  > _east))
        ) AND
	    [a.wkt] Intersects [b.geom]
),
papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		--b.geom as pt,
		x, y,
        z,
		a.geom as footprint
	FROM footprints a
	LEFT JOIN
    pointcloud_ground b ON
    --[a.geom] Intersects [b.geom]
    [a.geom] Intersects [x, y, z, 28992]
),
footprintpatch AS ( --get only points that fall inside building, patch them
	--SELECT id, pt as geom, footprint, min(z) as min
	SELECT id, footprint, min(z) as min
	FROM papoints
    WHERE
        --[footprint] Intersects [pt]
        [footprint] Intersects [x, y, z, 28992]
	--GROUP BY id, geom, footprint
	GROUP BY id, footprint
),
polygons AS (
	SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min+0.4),0,0,0.2) as geom FROM footprintpatch
)
SELECT id, 'steiger' as type, 'grey' as color, ST_AsX3D(p.geom, 4.0, 0) as geom FROM polygons p;
