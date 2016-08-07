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

drop table bounds;
create table bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
) WITH DATA;

drop table pointcloud_unclassified;
create table pointcloud_unclassified AS(
	SELECT ST_SetSRID(ST_MakePoint(x, y, z), 28992) as geom, c
	FROM
        C_30FZ1, bounds 
	WHERE
    --ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
    x between _west and _east and
    y between _south and _north and
	Contains(geom, x, y) and
    c = 2
) WITH DATA;

drop table points_filtered;
create table points_filtered AS (
	SELECT * FROM pointcloud_unclassified WHERE rand() > 0.2 
) WITH DATA;

SELECT NEXT VALUE FOR "counter" as id, 'ground' as type, '0.2 0.2 0.2' as color, ST_AsX3D(ST_Collect(geom), 4.0, 0) as geom FROM points_filtered a;
