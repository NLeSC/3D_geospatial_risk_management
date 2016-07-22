declare _west integer;
declare _south integer;
declare _east integer;
declare _north integer;
set _west = 93816;
set _east = 93916;
set _south = 463891;
set _north = 463991;

drop table bounds;
create table bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) as geom
)with data; 

drop table pointcloud;
create table pointcloud AS (
	SELECT x, y, z
	FROM ahn3, bounds
	WHERE 
    x between 93816 and 93916 and
    y between 463891 and 463991 and
    --ST_DWithin(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992),10) --patches should be INSIDE bounds
    Contains(geom, x, y)
    and c = 6
) with data;

--a.geometrie2dgrondvlak does not exist
drop table prefootprints;
create table prefootprints AS (
	SELECT
		--a.ogc_fid id,
		1 as id,
		ST_Simplify(ST_Force2D(ST_Union(geometrie2dgrondvlak)),0.95) as geom
	FROM bgt_buildingpart a, bounds b
	WHERE ST_Area(a.geometrie2dgrondvlak) > 30
	AND eindregistratie Is Null
	AND ST_IsValid(a.geometrie2dgrondvlak)
	AND ST_Intersects(a.geometrie2dgrondvlak, b.geom)
	AND ST_Intersects(ST_Centroid(a.geometrie2dgrondvlak), b.geom)
) with data;

drop table footprints;
create table footprints AS (
	SELECT id, ST_Dump(geom) as geom FROM prefootprints
) with data;

drop table stats_fast;
create table stats_fast AS (
	SELECT 
		avg(z) max,
		min(z) min,
		footprints.id,
		geom as footprint
	FROM footprints, pointcloud
	--LEFT JOIN pointcloud ON (ST_Intersects(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992)))
	WHERE ST_Intersects(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992))
	GROUP BY footprints.id, footprint
) with data;

drop table polygons;
create table polygons AS (
	SELECT 
		id,
		ST_Translate(footprint,0,0, max-min) as geom
    FROM stats_fast
) with data;

drop table rings;
create table rings AS (
SELECT id, ST_ExteriorRing(ST_GeometryN(geom,1)) as geom
	FROM polygons
) with data;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;

drop table skeleton;
create table skeleton AS (
	SELECT id, NEXT VALUE FOR "counter" as counter, (ST_Dump(ST_StraightSkeleton(geom))).geom as geom
	FROM footprints
) with data;

drop table skeletonpts;
create table skeletonpts AS (
	SELECT id, counter, (ST_DumpPoints(geom)).*
	FROM skeleton
) with data;

drop table skeletonpoints_patch;
create table skeletonpoints_patch AS ( --get closest patch to every vertex
	SELECT a.id, a.counter, a.path, a.geom,  --find closes patch to point
		COALESCE(b.pa, (
			SELECT b.pa FROM pointcloud b
			ORDER BY a.geom <#> Geometry(b.pa)
			LIMIT 1)
		) pa
	FROM skeletonpts a, pointcloud b
	WHERE ST_Intersects(a.geom,	ST_SetSRID(ST_MakePoint(x, y, z), 28992))
) with data;

drop table emptyz;
create table emptyz AS ( --find closest pt for every boundary point
	SELECT a.*, ( --find closest pc.pt to point
		SELECT b.pt FROM (SELECT PC_Explode(a.pa) pt ) b
		ORDER BY a.geom <#> Geometry(b.pt)
		LIMIT 1
		) pt
	FROM skeletonpoints_patch a
) with data;

--Problem, get the first of z, ask for clarification

drop table filledz;
create table filledz AS (
	SELECT id,counter, path, PC_Get(first(pt),'z') z, 
	ST_Translate(St_Force3D(geom), 0,0,PC_Get(first(pt),'z')) geom
	FROM emptyz
	GROUP BY id, counter, path, geom
	ORDER BY id, path
) with data;

drop table skeletonz;
create table skeletonz AS (
	SELECT id, counter, ST_MakeLine(geom) as geom
	FROM filledz
	GROUP BY id,counter
	UNION ALL
	SELECT id, 
	0 AS counter, geom
	FROM rings
) with data;

drop table unions;
create table unions AS (
	SELECT id, ST_Union(geom) as geom FROM skeletonz
	GROUP BY id
) with data;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, ST_Polygonize(geom) as geom 
	FROM unions
	GROUP BY id
) with data;

drop table dumped;
create table dumped AS (
	SELECT id, (ST_Dump(geom)).geom as geom
	FROM polygonsz
) with data;

SELECT id, 'roof' as type, 'red' as color, ST_AsX3d(ST_Collect(p.geom)) geom FROM dumped p GROUP BY p.id;
