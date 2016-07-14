WITH 
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
),
pointcloud_unclassified AS(
	SELECT 
		PC_FilterGreaterThan(
			PC_FilterEquals(
				PC_FilterEquals(pa,'classification',1),
			'NumberOfReturns',1),
		'Intensity',150)
	 pa  
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10) --patches should be INSIDE bounds
),

points AS (
	SELECT a.ogc_fid id, a.wkb_geometry geom 
	FROM bgt_import2.paal_2dactueelbestaand a, bounds b 
	WHERE (plus_type = 'lichtmast' OR plus_type Is Null)
	AND ST_Intersects(a.wkb_geometry, b.geom)
),
pointsz As (
	SELECT a.id, ST_Translate(ST_Force3D(a.geom),0,0,COALESCE(PC_PatchAvg(PC_Union(pa), 'z'),-99)+5) geom
	FROM points a
	LEFT JOIN pointcloud_unclassified b ON ST_DWithin(
		geometry(b.pa), 
		a.geom,1
	)
	GROUP BY a.id, a.geom
)
SELECT id, 'light' as type, ST_X(geom) x, ST_Y(geom) y, ST_Z(geom) z FROM pointsz;