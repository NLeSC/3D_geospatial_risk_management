WITH points AS (
	SELECT x,y,z
    -- FROM ahn3
    FROM C_30FZ1
	WHERE
	c = 2
	AND x between _west AND _east
	AND y between _south AND  _north
	--SAMPLE 1000
)
,polygons AS (
	SELECT ST_MakePolygon(ST_ExteriorRing(polygonwkb)) as geom
	FROM ST_DUMP((
		SELECT ST_Triangulate2DZ(ST_Collect(St_MakePoint(x,y,z)),0) 
		FROM points
	))
)
SELECT '1' AS id, 'land' AS type, 'grey' as color,
St_AsX3D(ST_Collect(geom), 4.0, 0) as geom 
FROM polygons
GROUP BY type;
