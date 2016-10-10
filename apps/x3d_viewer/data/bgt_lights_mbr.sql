


 with
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_unclassified AS(
	SELECT
		ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, z
	FROM ahn3, bounds
	WHERE
        x between _west and _east and
        y between _south and _north and
        --ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
        [geom] DWithin [x, y, z, 28992, 10] and--patches should be INSIDE bounds
        c = 1 and
        r = 1 and
        i > 150
),
points AS (
	--SELECT a.gml_id as id, a.wkt as geom
	SELECT a.ogc_fid as id, a.wkt as geom
	FROM bgt_paal a, bounds d
	WHERE
    (NOT
    ((a.col_ymax < _south) OR
    (a.col_ymin  > _north) OR
    (a.col_xmax  < _west) OR
    (a.col_xmin  > _east))
    ) AND
    (plus_type = 'lichtmast' OR plus_type Is Null)
	AND [a.wkt] Intersects [d.geom]
),
pointsz As (
	SELECT a.id, ST_Translate(ST_Force3D(a.geom), 0, 0, avg(z)+5) as geom
	FROM points a
	LEFT JOIN
    pointcloud_unclassified b ON
    --ST_DWithin(b.geom, a.geom,1)
    [b.geom] DWithin [a.geom,1]
	GROUP BY a.id, a.geom
)
SELECT id, 'light' as type, ST_X(geom) as x, ST_Y(geom) as y, ST_Z(geom) as z FROM pointsz;
