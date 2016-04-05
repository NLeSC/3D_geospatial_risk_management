declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816;
set _south = 93916;
set _east  = 463891;
set _north = 463991;

drop table bounds;
create table bounds AS 	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom with data;

drop table pointcloud;
create table pointcloud AS (
	SELECT PC_FilterEquals(pa,'classification',6) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
) with data;

drop table footprints;
create table footprints AS (
	SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(geometrie2dgrondvlak,0.4),1)) geom,
	a.ogc_fid id,
	0 bouwjaar
	FROM bgt_import.buildingpart a, bounds b
	WHERE 1 = 1
	--AND a.ogc_fid = 688393 --DEBUG
	--AND bgt_status = 'bestaand'
	AND ST_Area(a.geometrie2dgrondvlak) > 30
	AND ST_Intersects(a.geometrie2dgrondvlak, b.geom)
	AND ST_Intersects(ST_Centroid(a.geometrie2dgrondvlak), b.geom)
	AND ST_IsValid(a.geometrie2dgrondvlak)
    --AND ST_GeometryType(a.geometrie2dgrondvlak) = 'ST_MultiPolygon'
) with data;

drop table papoints;
create table papoints AS ( --get points from intersecting patches
	SELECT 
		a.id,
		PC_Explode(b.pa) pt,
		geom footprint
	FROM footprints a
	LEFT JOIN pointcloud b ON (ST_Intersects(a.geom, geometry(b.pa)))
) with data;

drop table stats_fast;
create table stats_fast AS (
	SELECT 
		PC_PatchAvg(PC_Union(pa),'z') max,
		PC_PatchMin(PC_Union(pa),'z') min,
		footprints.id,
		bouwjaar,
		geom footprint
	FROM footprints 
	--LEFT JOIN ahn_pointcloud.ahn2objects ON (ST_Intersects(geom, geometry(pa)))
	LEFT JOIN pointcloud ON (ST_Intersects(geom, geometry(pa)))
	GROUP BY footprints.id, footprint, bouwjaar
) with data;

drop table polygons;
create table polygons AS (
	SELECT 
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min)
			, 0,0,max-min -2)
		) 
		geom FROM stats_fast
	--SELECT ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
) with data;

SELECT id,
--s.type as type,
'building' as type,
'red' color, ST_AsX3D((p.geom)) geom
FROM polygons p;
