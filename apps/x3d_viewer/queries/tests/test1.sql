drop table pointcloud;
trace create table pointcloud AS (
        SELECT x, y, z
        FROM ahn3, bounds
        WHERE
        c = 6 and
        x between 93816.0 and 93916.0 and
        y between 463891.0 and 463991.0 and
        Contains(geom, x, y)
        ) with data;
