DROP FUNCTION patch_to_geom;
CREATE FUNCTION patch_to_geom(ingeom geometry) RETURNS geometry
BEGIN
    Declare table _papoints( x double, y double, z double);
    Declare table _edge_points( path string, geom geometry);
    Declare table _emptyz( path string, geom geometry, z double, dist double);
    Declare table _ranktest( path string, geom geometry, z double, dist double, rank int);
    Declare table _filledz( path string, geom geometry);
    Declare table _line_z(geom geometry);

    insert into _papoints SELECT x, y, z from pointcloud_ground;
    insert into _edge_points SELECT path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ingeom)) d;
    insert into _emptyz SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MAkePoint(x, y), 28992)) as dist FROM _edge_points a, _papoints b;
    insert into _ranktest select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) from _emptyz;
    insert into _filledz select path, ST_SetSRID(ST_MakePoint(ST_X(geom), ST_Y(geom), z), 28992) as geom from _ranktest where rank = 1 order by path;
    insert into _line_z SELECT ST_MakeLine(geom) as geom FROM _filledz;
return
    select ST_Polygon(geom, 28992) from _line_z;
END;
