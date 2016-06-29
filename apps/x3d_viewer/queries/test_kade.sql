drop table bounds;
create table bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
) with data;

drop table pointcloud_ground;
create table pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa --ground points
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_DWithin(geom, Geometry(pa),10)
) with data;

drop table pointcloud_all;
create table pointcloud_all AS (
	SELECT pa pa --all points
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_DWithin(geom, Geometry(pa),10)
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.geom, b.geom)) geom,
	a.ogc_fid id
	FROM bgt_import.polygons a, bounds b
	WHERE 1 = 1
	AND (type = 'kademuur' OR class = 'border')
	AND ST_Intersects(a.geom, b.geom)
	--AND ST_Intersects(ST_Centroid(a.geom), b.geom)
) with data;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		PC_Explode(b.pa) pt,
		geom footprint
	FROM footprints a
	LEFT JOIN pointcloud_ground b ON (ST_Intersects(a.geom, geometry(b.pa)))
) with data;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, PC_PatchMin(PC_Union(pa), 'z') min
	FROM footprints a
	LEFT JOIN pointcloud_all b ON (ST_Intersects(a.geom, geometry(b.pa)))
	GROUP BY a.id
) with data;

drop table footprintpatch;
create table footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, PC_Patch(pt) pa, footprint
	FROM papoints WHERE ST_Intersects(footprint, Geometry(pt))
	GROUP BY id, footprint
) with data;

drop table stats;
create table stats AS (
	SELECT  a.id, footprint,
		PC_PatchAvg(pa, 'z') max,
		min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
) with data;

drop table polygons;
create table polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, min)), 0,0,max-min) geom FROM stats
) with data;

SELECT id,'kade' as type, 'grey' color, ST_AsX3D(p.geom) geom
FROM polygons p;
