declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
declare _geom2 string;

set _west = 93816;
set _south = 93916;
set _east  = 463891;
set _north = 463991;
set _geom2 = 'POLYGON ((93910.602 463934.263, 93914.44 463934.856, 93907.227 463933.742, 93910.602 463934.263))';

CREATE FUNCTION patch_to_geom(ingeom geometry) RETURNS geometry
BEGIN
    return
        WITH 
         papoints AS (
            SELECT x, y, z from pointcloud_ground
         ),
         edge_points AS (
            SELECT path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(ST_SETSRID(ST_GeometryFromText(_geom2),28992)))         
         ), 
         emptyz as (   
             SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MAkePoint(x, y), 28992)) as dist
             FROM edge_points a, papoints b         
             --Order by path, dist
         ),
         ranktest as (
             select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) from emptyz
         ),
         filledz as (
            select path, ST_SetSRID(ST_MakePoint(ST_X(geom), ST_Y(geom), z), 28992) as geom from ranktest where "L2" = 1 --order by path
         ),
         line_z as (
            SELECT ST_MakeLine(geom) as geom FROM filledz
         )  
        select ST_Polygon(geom, 28992) from line_z;
END;














drop table bounds;
create table bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) as geom
) with data;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT x, y, z 
	FROM ahn3, bounds
	WHERE 
    x between 93816.0 and 93916.0 and
    y between 463891.0 and 463991.0 and
    --ST_Intersects(geom, Geometry(pa)) and
	Contains(geom, x, y)
    c = 2
) with data;

drop table terrain;
create table terrain AS (
	SELECT nextval('counter') as id, ogc_fid as fid, 'unknown' as type, class,
			d.geom
	FROM bgt_polygons a, bounds b, ST_Dump(ST_Intersection(a.geom, b.geom)) d
	WHERE ST_Intersects(a.geom, b.geom)
	and class <> 'water'
	and type <> 'kademuur'
	and type <> 'pand'
) with data;

drop table polygons;
create table polygons AS (
	SELECT * FROM terrain
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
	AND type <> 'water'
) with data;

        WITH 
         edge_points AS (
            SELECT path, pointg as geom FROM ST_DumpPoints(ST_ExteriorRing(select geom from polygons)) d         
         ), 
         emptyz as (   
             SELECT a.path as path, a.geom as geom , b.z as z, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MAkePoint(x, y), 28992)) as dist
             FROM edge_points a, pointcloud_ground b         
             --Order by path, dist
         ),
         ranktest as (
             select path, geom, z, dist, RANK() over (PARTITION BY path, geom order by path, dist ASC) from emptyz
         ),
         filledz as (
            select path, ST_SetSRID(ST_MakePoint(ST_X(geom), ST_Y(geom), z), 28992) as geom from ranktest where "L2" = 1 --order by path
         ),
         line_z as (
            SELECT ST_MakeLine(geom) as geom FROM filledz
         )  
        select ST_Polygon(geom, 28992) from line_z;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, fid, type, class, patch_to_geom(PC_Union(b.pa), geom) geom
	FROM polygons a 
	LEFT JOIN pointcloud_ground b
	ON ST_Intersects(geom,Geometry(b.pa))
	GROUP BY id, fid, type, class, geom
) with data;

drop table basepoints;
create table basepoints AS (
	SELECT id,geom FROM polygonsz
	WHERE ST_IsValid(geom)
) with data;

drop table triangles;
create table triangles AS (
	SELECT 
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id
) with data;

drop table assign_triags;
create table assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
) with data;

SELECT _south::text || _west::text || p.id as id, p.type as type,
	ST_AsX3D(ST_Collect(p.geom),3) geom
FROM assign_triags p
GROUP BY p.id, p.type;
