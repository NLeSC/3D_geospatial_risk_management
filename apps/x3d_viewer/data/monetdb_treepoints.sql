 with points AS (
    SELECT x,y,z 
    --FROM ahn3
    FROM C_30FZ1
    WHERE 
    c = 1 AND
    r < n -1 AND
    i < 150 AND
    x between _west AND _east AND y between _south AND  _north
    --SAMPLE 1000
    )
SELECT '1' AS id, 'tree' AS type, 'green' As color, St_AsX3D(ST_Collect(ST_SetSrid(St_MakePoint(x,y,z),28992)),4.0,0) FROM points;
