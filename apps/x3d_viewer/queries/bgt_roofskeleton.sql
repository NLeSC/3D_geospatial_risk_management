WITH bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
), 
	pointcloud AS (
					SELECT PC_FilterEquals(pa,'classification',6) pa
					FROM ahn3_pointcloud.vw_ahn3, bounds
					WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
	),

	prefootprints AS (
		SELECT
			--a.ogc_fid id,
			1 as id,
			ST_Simplify(ST_Force2D(ST_Union(geometrie2dgrondvlak)),0.95) geom
		FROM bgt_import.buildingpart a, bounds b
		WHERE ST_Area(a.geometrie2dgrondvlak) > 30
		AND eindregistratie Is Null
		AND ST_IsValid(a.geometrie2dgrondvlak)
		AND ST_Intersects(a.geometrie2dgrondvlak, b.geom)
		AND ST_Intersects(ST_Centroid(a.geometrie2dgrondvlak), b.geom)
	),
	footprints AS (
		SELECT id, (ST_Dump(geom)).geom geom FROM prefootprints
	),
	stats_fast AS (
		SELECT 
			PC_PatchAvg(PC_Union(pa),'z') max,
			PC_PatchMin(PC_Union(pa),'z') min,
			footprints.id,
			geom footprint
		FROM footprints 
		--LEFT JOIN ahn_pointcloud.ahn2objects ON (ST_Intersects(geom, geometry(pa)))
		LEFT JOIN pointcloud ON (ST_Intersects(geom, geometry(pa)))
		GROUP BY footprints.id, footprint
	),
	polygons AS (
		SELECT 
			id,
			ST_Translate(footprint,0,0, max-min)
			geom FROM stats_fast
		--SELECT ST_Tesselate(ST_Translate(footprint,0,0, min + 20)) geom FROM stats_fast
)

,	rings AS (
SELECT id, ST_ExteriorRing(ST_GeometryN(geom,1)) geom
					FROM polygons
)
,skeleton AS (
					SELECT id, nextval('counter') counter, (ST_Dump(ST_StraightSkeleton(geom))).geom geom
					FROM footprints
	)
	,skeletonpts AS (
					SELECT id, counter, (ST_DumpPoints(geom)).*
					FROM skeleton
	)
	,skeletonpoints_patch AS ( --get closest patch to every vertex
					SELECT a.id, a.counter, a.path, a.geom,  --find closes patch to point
					COALESCE(b.pa,
									(
									SELECT b.pa FROM pointcloud b
									ORDER BY a.geom <#> Geometry(b.pa)
									LIMIT 1
									)
					) pa
					FROM skeletonpts a LEFT JOIN pointcloud b
					ON ST_Intersects(
									a.geom,
									geometry(pa)
					)
	)
	,emptyz AS ( --find closest pt for every boundary point
					SELECT a.*, ( --find closest pc.pt to point
									SELECT b.pt FROM (SELECT PC_Explode(a.pa) pt ) b
									ORDER BY a.geom <#> Geometry(b.pt)
									LIMIT 1
					) pt
					FROM skeletonpoints_patch a
	)
	,filledz AS (
					SELECT id,counter, path, PC_Get(first(pt),'z') z, 
					ST_Translate(St_Force3D(geom), 0,0,PC_Get(first(pt),'z')) geom
					FROM emptyz
					GROUP BY id, counter, path, geom
					ORDER BY id, path
	)
	,skeletonz AS (
					SELECT id, counter, ST_MakeLine(geom) geom
					FROM filledz
					GROUP BY id,counter
					UNION ALL
					SELECT id, 0 AS counter, geom
					FROM rings
	),
	unions AS (
SELECT id, ST_Union(geom) geom FROM skeletonz
GROUP BY id
),
	polygonsz AS (
					SELECT id, ST_Polygonize(geom) geom 
					FROM unions
					GROUP BY id
	),
	dumped AS (
SELECT id, (ST_Dump(geom)).geom geom
FROM polygonsz

	
	)
	SELECT
	id,
	'roof' as type,
	'red' color, ST_AsX3d(ST_Collect(p.geom)) geom
	FROM dumped p
	GROUP BY p.id
	;