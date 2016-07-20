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
pointcloud_unclassified AS(
	SELECT
		ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, z
	FROM C_30FZ1, bounds
	WHERE
        --ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
        x between 93816.0 and 93916.0 and
        y between 463891.0 and 463991.0 and
        --ST_Intersects(geom, Geometry(pa))
    	Contains(geom, x, y) and
        c = 1 and
        r = 1 and
        i > 150
),

points AS (
	SELECT a.gml_id as id, a.wkt as geom
	FROM bgt_paal a, bounds b
	WHERE
    (plus_type = 'lichtmast' OR plus_type Is Null)
	AND [a.wkt] Intersects [b.geom]
),
pointsz As (
	SELECT a.id, ST_Translate(ST_Force3D(a.geom), 0, 0, avg(z)+5) as geom
	FROM points a
	LEFT JOIN
    pointcloud_unclassified b ON
    ST_DWithin(b.geom, a.geom,1)
	GROUP BY a.id, a.geom
)
SELECT id, 'light' as type, ST_X(geom) as x, ST_Y(geom) as y, ST_Z(geom) as z FROM pointsz;
