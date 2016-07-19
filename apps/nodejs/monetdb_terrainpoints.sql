WITH points AS (
	SELECT x,y,z FROM ahn3_c_30fz1
	WHERE
	c = 2
	AND x between _west AND _east
	AND y between _south AND  _north
	SAMPLE 10000
)
SELECT '1' AS id, 'terrain' AS type, 'yellow' As color,
St_AsX3D(ST_Collect(St_MakePoint(x,y,z)),4.0,0)
FROM points;