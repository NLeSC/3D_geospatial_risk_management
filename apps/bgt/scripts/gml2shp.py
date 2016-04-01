#!/usr/bin/env python

import sys
import ogr2ogr

def main(args):
    if (len(args) == 3):
        gmlFile=args[1]
        shpFile=args[2]
    else:
        print "./gml2shp.py <gml_file> <shape_file>\n"
        sys.exit(0)
    #note: main is expecting sys.argv, where the first argument is the script name
    #so, the argument indices in the array need to be offset by 1

    #Example using ogr2ogr
    #ogr2ogr.main(["","-f", "KML", "out.kml", "data/san_andres_y_providencia_administrative.shp"])

    #GML to multiple shape files
    #ogr2ogr -f "ESRI Shapefile" polygon.shp multipolygon.gml
        #GPS
        #ogr2ogr.main(["","-t_srs", "EPSG:4326", "-f", "ESRI Shapefile", "bgt_tunnelpart.shp", "bgt_tunnelpart.gml"])
    
        #lat and long
    #ogr2ogr.main(["","-t_srs" , "EPSG:28992", "-f", "ESRI Shapefile", "bgt_tunnelpart.shp", "bgt_tunnelpart.gml"])
    ogr2ogr.main(["","-t_srs" , "EPSG:28992", "-f", "ESRI Shapefile", shpFile, gmlFile])

    #GML to a single shape file, however, such shape file does not contain the first feature's and the third feature's attribute
    #ogr2ogr -f "ESRI Shapefile" polygon.shp multipolygon.gml multipolygon
    #ogr2ogr.main(["", "-f", "ESRI Shapefile", "bgt_tunnelpart.shp", "bgt_tunnelpart.gml", "bgt_tunnelpart"])

    #FROM SHP to CSV
    #ogr2ogr -f CSV output.csv bgt_tunnelpart.shp -lco GEOMETRY=AS_WKT

if __name__ == '__main__':
    if not main(sys.argv):
        sys.exit(1)
    else:
        sys.exit(0)
