/*
declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
declare _segmentlength integer;

set _west = 93816.0;
set _east = 93916.0;
set _south = 463891.0;
set _north = 463991.0;
*/
/*
--DROP TABLE points;
CREATE TABLE T_west AS (
	SELECT ST_SetSrid(St_MakePoint(x,y,z),28992) AS geom
	FROM ahn3_c_30fz1 
	WHERE x between _west AND _east
	AND y between _south AND  _north
	AND c = 2 
	SAMPLE 10000
) WITH data;

CREATE TABLE T_east AS (
	SELECT ST_SetSrid(ST_MakeEnvelope(_west, _south, _east, _north, 28992),28992) as geom
) WITH data;

CREATE TABLE T_south AS (
	SELECT bgt_fysiekvoorkomen as type, wkt as wkt 
	FROM sys.bgt_begroeidterreindeel_2d AS a, T_east AS b
	WHERE [a.wkt] Intersects [b.geom]
	--WHERE ST_Intersects(a.wkt, b.geom)
) WITH data;

CREATE TABLE T_north AS (
	SELECT 
	type, T_west.geom
	FROM T_west, T_south
	WHERE [wkt] Intersects [geom]
) WITH data;

SELECT
	'1' AS id, 'terrain' AS type, 'red' As color,
	ST_AsX3D(
		ST_Collect(geom)
	,3.0,0)
	as geom
FROM T_north
GROUP BY type;
*/

WITH points AS (
	SELECT x,y,z FROM ahn3_c_30fz1
	WHERE
	c = 2
	AND x between _west AND _east
	AND y between _south AND  _north
	SAMPLE 1000
)
,polygons AS (
	SELECT ST_MakePolygon(ST_ExteriorRing(polygonwkb)) as geom
	FROM ST_DUMP((
		SELECT ST_Triangulate2DZ(ST_Collect(St_MakePoint(x,y,z)),0) 
		FROM points
	))
)
SELECT '1' AS id, 'land' AS type, 'grey' as color,
--St_Collect(geom)
--geom
St_AsX3D(ST_Collect(geom), 4.0, 0) as geom 
FROM polygons
GROUP BY type;
