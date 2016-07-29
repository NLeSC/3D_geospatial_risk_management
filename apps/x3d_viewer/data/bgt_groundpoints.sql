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

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
),
pointcloud_unclassified AS(
	SELECT ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, c
	FROM
        ahn3, bounds
	WHERE
    x between _west and _east and
    y between _south and _north and
	Contains(geom, x, y, z, 28992) and
    c = 2
),
points_filtered AS (
	SELECT * FROM pointcloud_unclassified WHERE rand() > 0.2
)
SELECT NEXT VALUE FOR "counter" as id, 'ground' as type, '0.2 0.2 0.2' as color, ST_AsX3D(ST_Collect(geom), 4.0, 0) as geom FROM points_filtered a;
