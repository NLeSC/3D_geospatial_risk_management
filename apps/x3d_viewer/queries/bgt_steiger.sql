WITH 
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
),
pointcloud_ground AS (
	SELECT PC_FilterGreaterThan(
			PC_FilterEquals(
				PC_FilterEquals(pa,'classification',1),
			'NumberOfReturns',1),
		'Intensity',150) pa --unclassified points 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10)
),
pointcloud_all AS (
	SELECT pa pa --all points 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_DWithin(geom, Geometry(pa),10)
),
footprints AS (
	SELECT ST_Force3D(ST_Intersection(a.wkb_geometry, b.geom)) geom,
	a.ogc_fid id
	FROM bgt_import2.kunstwerkdeel_2dactueelbestaand a, bounds b
	WHERE 1 = 1
	AND (bgt_type = 'steiger') 
	AND ST_Intersects(a.wkb_geometry, b.geom)
),
papoints AS ( --get points from intersecting patches
	SELECT 
		a.id,
		PC_Explode(b.pa) pt,
		geom footprint
	FROM footprints a
	LEFT JOIN pointcloud_ground b ON (ST_Intersects(a.geom, geometry(b.pa)))
),
/*
papatch AS (
	SELECT
		a.id, PC_PatchMin(PC_Union(pa), 'z') min
	FROM footprints a
	LEFT JOIN pointcloud_all b ON (ST_Intersects(a.geom, geometry(b.pa)))
	GROUP BY a.id
),*/
footprintpatch AS ( --get only points that fall inside building, patch them
	SELECT id, PC_Patch(pt) pa, footprint
	FROM papoints WHERE ST_Intersects(footprint, Geometry(pt))
	GROUP BY id, footprint
),
/*
stats AS (
	SELECT  a.id, footprint, 
		PC_PatchAvg(pa, 'z') max,
		min
	FROM footprintpatch a, papatch b
	WHERE (a.id = b.id)
),*/
polygons AS (
	SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, PC_PatchMin(pa,'z')+0.4)),0,0,0.2) geom FROM footprintpatch
)
SELECT id,'steiger' as type, 'grey' color, ST_AsX3D(p.geom) geom
FROM polygons p