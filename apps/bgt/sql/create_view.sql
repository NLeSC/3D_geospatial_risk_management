drop table bgt_polygons;

CREATE TABLE bgt_polygons AS (
SELECT gml_id as ogc_fid, 'building' AS class, "function" as type, wkt as geom 
FROM bgt_buildinginstallation
UNION ALL
SELECT gml_id as ogc_fid, 'building' AS class, bgt_type as type, wkt as geom 
FROM bgt_overigbouwwerk
UNION ALL
SELECT gml_id as ogc_fid, 'building' AS class, 'pand' as type, wkt as geom 
FROM bgt_BuildingPart
UNION ALL
SELECT gml_id as ogc_fid, 'plantcover' AS class, "class" as type, wkt as geom 
FROM bgt_PlantCover
UNION ALL
SELECT gml_id as ogc_fid, 'bare' AS class, bgt_fysiekVoorkomen as type, wkt as geom 
FROM bgt_OnbegroeidTerreindeel
UNION ALL
SELECT gml_id as ogc_fid, 'water' AS class, "class" as type, wkt as geom
FROM bgt_Waterdeel
UNION ALL
SELECT gml_id as ogc_fid, 'water' AS class, "class" as type, wkt as geom 
FROM bgt_OndersteunendWaterdeel
UNION ALL
SELECT a.gml_id as ogc_fid, 'road' AS class, a."function" as type, a.wkt as geom 
FROM bgt_TrafficArea a, bgt_BridgeConstructionElement b 
WHERE a.relatieveHoogteligging > -1 and St_Intersects(a.wkt, b.wkt) AND St_Contains(ST_buffer(b.wkt,1), a.wkt) 
AND b.wkt Is Null
UNION ALL
SELECT gml_id as ogc_fid, 'road' AS class, "function" as type, wkt as geom
FROM bgt_AuxiliaryTrafficArea
WHERE relatieveHoogteligging > -1
UNION ALL
SELECT gml_id as ogc_fid, 'road' AS class, 'tunnel' as type, wkt as geom
FROM bgt_TunnelPart
UNION ALL
--SELECT gml_id as ogc_fid, 'bridge' AS class, typeoverbruggingsdeel as type, wkt as geom FROM overbruggingsdeel
--UNION ALL
SELECT a.gml_id as ogc_fid, 'border' AS class, a.bgt_type as type, a.wkt as geom
FROM bgt_Scheiding a, bgt_BridgeConstructionElement b
WHERE a.relatieveHoogteligging > -1 and St_Intersects(a.wkt, b.wkt) AND St_Contains(ST_buffer(b.wkt,1), a.wkt) 
AND b.wkt Is Null) WITH DATA;

UPDATE bgt_polygons SET geom = ST_SetSrid(geom, 28992);
