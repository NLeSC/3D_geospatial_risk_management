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
	--SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
	SELECT ST_MakeEnvelope(_west+10, _south+10, _east+10, _north+10, 28992) as geom
),
pointcloud_unclassified AS(
	SELECT
        ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom
	FROM
        ahn3, bounds
	WHERE
    --ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
    x between _west and _east and
    y between _south and _north and
    c = 1 AND
    i < 150 AND
    r < n-1 and
    --[geom] DWithin [x, y, z, 28992, 10] --patches should be INSIDE bounds
    Contains(geom, x, y, z, 28992) --patches should be INSIDE bounds
)
SELECT NEXT VALUE for "counter" as id, 'tree' as type, '0 ' || rand() * 0.1 ||' 0' as color, ST_AsX3D(ST_Collect(geom), 4.0, 0) as geom FROM pointcloud_unclassified a;
