**Changes applied to the SQL code to continue query testing:**

ST_DWithin(geom, Geometry(pa),10)
became
ST_DWithin(geom, ST_geomFromText('Point( 10.0 11.0 12.0)', 28992), 10)


All tables from bgt, to the name you should append bgt_

geometrie2dgrondvlak was renamed kmlgeometry

SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(kmlgeometry,0.4),1)) as geom,
became
SELECT ST_Force3D(ST_GeometryN(kmlgeometry,1)) as geom,

a.ogc_fid
became
gml_id
