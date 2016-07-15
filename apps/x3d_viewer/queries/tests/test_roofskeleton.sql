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
		--ST_Simplify(ST_Force2D(ST_Union(wkt)), 0.95) as geom
		ST_SimplifyPreserveTopology(ST_Force2D(ST_Union(wkt)), 0.95) as geom
	FROM bgt_buildingpart a, bounds b
	WHERE ST_Area(a.wkt) > 30
	--AND eindregistratie Is Null
	AND ST_IsValid(a.wkt)
	AND ST_Intersects(a.wkt, b.geom)
	AND ST_Intersects(ST_Centroid(a.wkt), b.geom)
) with data;

DROP SEQUENCE "counter_id";
CREATE SEQUENCE "counter_id" AS INTEGER;

drop table footprints;
create table footprints AS (
	SELECT NEXT VALUE FOR "counter_id" as footprints_id, id, polygonwkb as geom FROM ST_DUMP((select geom from prefootprints)) d
) with data;

drop table stats_fast;
create table stats_fast AS (
	SELECT 
		footprints.footprints_id as footprints_id,
		footprints.id as id,
		geom as footprint,
		avg(z) as max,
		min(z) as min
	FROM footprints, pointcloud
	--LEFT JOIN pointcloud ON (ST_Intersects(geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992)))
	WHERE ST_Intersects(ST_SetSRID(geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992))
	GROUP BY footprints_id, id, footprint
) with data;

drop table polygons;
create table polygons AS (
	SELECT 
        footprints_id,
		id,
		ST_Translate(footprint,0,0, max-min) as geom
    FROM stats_fast
) with data;

drop table rings;
create table rings AS (
SELECT footprints_id, id, ST_ExteriorRing(ST_GeometryN(geom,1)) as geom
	FROM polygons
) with data;

DROP SEQUENCE "counter";
CREATE SEQUENCE "counter" AS INTEGER;


----TODO: ST_DUMP needs to receive any type
drop table skeleton;
create table skeleton AS (
	SELECT parent as footprints_id, NEXT VALUE FOR "counter" as counter, d.polygonWKB as geom
	FROM ST_Dump((select geom, footprints_id from footprints)) d
) with data;

drop table skeletonpts_dump;
create table skeletonpts_dump AS (
	SELECT *
	FROM ST_DumpPoints((select geom, counter from skeleton)) d
) with data;

drop table skeletonpts;
create table skeletonpts AS (
	--SELECT id, counter, *
	SELECT s.footprints_id, f.id, s.counter, sd.pointG as geom
	FROM skeleton s, skeletonpts_dump sd, footprints f
    WHERE 
    s.counter =  sd.parent and
    s.footprints_id = f.footprints_id
) with data;

drop table skeletonpoints_dist;
create table skeletonpoints_dist as (
    select footprints_id , id, a.counter, a.geom, ST_SetSRID(ST_MakePoint(x, y, z), 28992) as pt, ST_Distance(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992)) as dist 
    from skeletonpts a, pointcloud b
    where
    ST_DWITHIN(ST_SetSRID(a.geom, 28992), ST_SetSRID(ST_MakePoint(x, y, z), 28992), 10)
) WITH DATA;

drop table skeletonpoints_rank;
create table skeletonpoints_rank as (
    select footprints_id, id, counter, geom, pt, dist, RANK() over (PARTITION BY footprints_id, id, counter, geom order by footprints_id, id, counter, dist ASC) as rank
    from skeletonpoints_dist
) WITH DATA;

drop table filledz;
create table filledz AS ( --get closest patch to every vertex
	SELECT footprints_id, id, counter, ST_Translate(St_Force3D(geom), 0, 0, ST_Z(pt)) as geom
    from skeletonpoints_rank
    where
    rank = 1 --find closes patch to point
) with data;


--TODO we need a subMakeLine, another aggregate function.
drop table skeletonz;
create table skeletonz AS (
	SELECT id, counter, ST_MakeLine(geom) as geom FROM filledz GROUP BY id,counter UNION ALL SELECT id, 0 AS counter, geom FROM rings
) with data;

drop table unions;
create table unions AS (
	SELECT id, ST_Union(geom) as geom FROM skeletonz GROUP BY id
) with data;

drop table polygonsz;
create table polygonsz AS (
	SELECT id, ST_Polygonize(geom) as geom FROM unions --GROUP BY id
) with data;

drop table dumped;
create table dumped AS (
    SELECT parent as id, polygonWKB as geom FROM ST_Dump((select id, geom from polygonsz)) d
) with data;

SELECT id, 'roof' as type, 'red' as color, ST_AsX3d(ST_Collect(p.geom), 4.0, 0) as geom FROM dumped p GROUP BY p.id;
