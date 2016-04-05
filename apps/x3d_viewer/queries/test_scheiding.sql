drop table bounds;
create table bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
) with data;

drop table pointcloud_building;
create table pointcloud_building AS (
	SELECT PC_FilterEquals(pa,'classification',1) pa --unclassified  
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(a.geom) geom,
	a.ogc_fid id
	FROM bgt_import.polygons a, bounds b
	WHERE 1 = 1
	AND type = 'muur'
	AND ST_Intersects(a.geom, b.geom)
	AND ST_Intersects(ST_Centroid(a.geom), b.geom)
) with data;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT 
		a.id,
		PC_Explode(b.pa) pt,
		geom footprint
	FROM footprints a
	LEFT JOIN pointcloud_building b ON (ST_Intersects(a.geom, geometry(b.pa)))
) with data;

drop table papatch;
create table papatch AS (
	SELECT
		a.id, PC_PatchMin(PC_Union(pa), 'z') min
	FROM footprints a
	LEFT JOIN pointcloud_building b ON (ST_Intersects(a.geom, geometry(b.pa)))
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

drop table stats_fast;
create table stats_fast AS (
	SELECT 
		PC_PatchAvg(PC_Union(pa),'z') max,
		PC_PatchMin(PC_Union(pa),'z') min,
		footprints.id,
		geom footprint
	FROM footprints 
	LEFT JOIN pointcloud_building ON (ST_Intersects(geom, geometry(pa)))
	GROUP BY footprints.id, footprint
) with data;

drop table polygons;
create table polygons AS (
	SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min), 0,0,max-min) geom FROM stats
	--SELECT id, ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
) with data;

SELECT id,'building' as type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom) geom
FROM polygons;
