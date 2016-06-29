declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816.0;
set _south = 93916.0;
set _east  = 463891.0;
set _north = 463991.0;

drop table bounds;
create table bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
) with data;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_Intersects(geom, Geometry(pa))
) with data;

drop table terrain;
create table terrain AS (
	SELECT nextval('counter') id, ogc_fid fid, COALESCE(type,'transitie') as type, class,
			(ST_Dump(
			ST_Intersection(a.geom, b.geom)
			)).geom
	FROM bgt_import.polygons a, bounds b
	WHERE ST_Intersects(a.geom, b.geom)
	and class != 'water'
	and type != 'kademuur'
	and type != 'pand'
) with data;

drop table polygons;
create table polygons AS (
	SELECT * FROM terrain
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
	AND type != 'water'
) with data;

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
