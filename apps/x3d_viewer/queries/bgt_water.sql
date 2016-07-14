WITH 
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
pointcloud_water AS (
	SELECT PC_FilterEquals(pa,'classification',9) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds 
	WHERE ST_Intersects(geom, Geometry(pa)) --patches should be INSIDE bounds
),
terrain AS (
	SELECT nextval('counter') id, ogc_fid fid, bgt_type as type, 'water'::text AS class,
	  (ST_Dump(
		ST_Intersection(a.wkb_geometry, b.geom)
	  )).geom
	FROM bgt_import2.waterdeel_2dactueelbestaand a, bounds b
	WHERE ST_Intersects(a.wkb_geometry, b.geom)
)
,polygons AS (
	SELECT * FROM terrain
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
)
,polygonsz AS ( 
	SELECT a.id, a.fid, a.type, a.class, 
	--ST_Translate(ST_Force3D(a.geom), 0,0,COALESCE(min(PC_PatchMin(b.pa,'z')),0)) geom
	ST_Translate(ST_Force3D(a.geom), 0,0,0) geom --fixed level
	FROM polygons a
	/*
	LEFT JOIN pointcloud_water b
	ON ST_Intersects(
		a.geom,
		geometry(pa)
	)*/
	GROUP BY a.id, a.fid, a.type, a.class, a.geom
)
,basepoints AS (
	SELECT id,geom FROM polygonsz
	WHERE ST_IsValid(geom)
)
,triangles AS (
	SELECT 
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id
)
,assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
)
SELECT _south::text || _west::text || p.id AS id, 
'water' as type,
ST_AsX3D(ST_Collect(p.geom),3) as geom
FROM assign_triags p
GROUP BY p.id, p.type;