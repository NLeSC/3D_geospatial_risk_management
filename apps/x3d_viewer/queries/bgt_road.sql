
WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),

mainroads AS (
	SELECT a.ogc_fid, 'road'::text AS class, a.bgt_functie as type, ST_Intersection(a.wkb_geometry,c.geom) geom 
	FROM bgt_import2.wegdeel_2d a
	LEFT JOIN bgt_import2.overbruggingsdeel_2d b
	ON (St_Intersects((a.wkb_geometry), (b.wkb_geometry)) AND St_Contains(ST_buffer((b.wkb_geometry),1), (a.wkb_geometry)))
	,bounds c
	WHERE a.relatieveHoogteligging = 0
	AND ST_CurveToLine(b.wkb_geometry) Is Null
	AND a.eindregistratie Is Null
	AND b.eindregistratie Is Null
	AND ST_Intersects(geom, a.wkb_geometry)
),
auxroads AS (
	SELECT ogc_fid, 'road'::text AS class, bgt_functie as type, ST_Intersection(wkb_geometry,geom) geom
	FROM bgt_import2.ondersteunendwegdeel_2d, bounds
	WHERE relatieveHoogteligging = 0
	AND eindregistratie Is Null
	AND ST_Intersects(geom, wkb_geometry)
),
tunnels AS (
	SELECT ogc_fid, 'road'::text AS class, 'tunnel'::text as type, ST_Intersection(wkb_geometry,geom) geom
	FROM bgt_import2.tunneldeel_2d, bounds
	WHERE eindregistratie Is Null
	AND ST_Intersects(geom, wkb_geometry)
),
pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_Intersects(geom, Geometry(pa))
	--Sometimes roads are incorrectly classified as bridges, so also include bridge points 
	/*UNION ALL
	SELECT PC_FilterEquals(pa,'classification',26) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE ST_Intersects(geom, Geometry(pa))*/
),
polygons AS (
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM mainroads
	UNION ALL
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM auxroads
	UNION ALL
	SELECT nextval('counter') id, ogc_fid fid, type, class,(ST_Dump(geom)).geom
	FROM tunnels
)
,polygonsz AS (
	SELECT id, fid, type, class, patch_to_geom(PC_Union(b.pa), geom) geom
	FROM polygons a 
	LEFT JOIN pointcloud_ground b
	ON ST_Intersects(geom,Geometry(b.pa))
	GROUP BY id, fid, type, class, geom
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

SELECT _south::text || _west::text || p.id as id, p.type as type,
	ST_AsX3D(ST_Collect(p.geom),5) geom
FROM assign_triags p
GROUP BY p.id, p.type