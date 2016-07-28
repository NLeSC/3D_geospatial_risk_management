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

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_unclassified AS(
	SELECT ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, c
	FROM
        C_30FZ1, bounds
	WHERE
    --ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
	Contains(geom, x, y) and
    c = 2
),
points_filtered AS (
	SELECT * FROM pointcloud_unclassified WHERE rand() > 0.2
)
SELECT NEXT VALUE FOR "counter" as id, 'ground' as type, '0.2 0.2 0.2' as color, ST_AsX3D(ST_Collect(geom), 4.0, 0) as geom FROM points_filtered a;
