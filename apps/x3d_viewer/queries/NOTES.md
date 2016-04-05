Functionality specific to PostGIS pointcloud extension:

PC_FilterEquals() Returns a patch with only points whose values are the same as the supplied values for the requested dimension.
More info about PointCloud extension`s functions: http://suite.opengeo.org/docs/latest/dataadmin/pointcloud/functions.html

PC_Explode
Set-returning function, converts patch into result set of one point record for each point in the patch.

PC_Union
aggregate function merges a result set of pcpatch entries into a single pcpatch.

PC_PatchAvg
Reads the values of the requested dimension for all points in the patch and returns the average of those values. Dimension name must exist in the schema.
Example:
SELECT PC_PatchMax(pa, 'x')
FROM patches WHERE id = 7;

PC_PatchMin
Reads the values of the requested dimension for all points in the patch and returns the minimum of those values. Dimension name must exist in the schema.

This one is missing:
ST_AsX3D
http://postgis.net/docs/ST_AsX3D.html

ST_Extrude
http://postgis.net/docs/ST_Extrude.html

ST_MultiPolygon
xxxxx

ST_Polygonize
http://postgis.net/docs/ST_Polygonize.html

ST_StraightSkeleton
http://postgis.net/docs/ST_StraightSkeleton.html

ST_Tesselate
http://postgis.net/docs/ST_Tesselate.html

ST_Triangulate2DZ
xxxx -> It looks like a CGAL thing

This one is not implemented, i.e., it is commented out:
ST_SimplifyPreserveTopology

It is implemented it needs extension:

ST_DWithin — Returns true if the geometries are within the specified distance of one another.
More info at: http://postgis.net/docs/ST_DWithin.html


Changes applied to the SQL code to continue query testing:
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


