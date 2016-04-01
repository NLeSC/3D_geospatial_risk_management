#!/usr/bin/env python

import ogr,csv,sys

def main(args):
    if (len(args) == 3):
        shpFile=args[1]
        csvFile=args[2]
    else:
        print "./shp2csv.py <shape_file> <csv_file>\n"
        sys.exit(0)

    shpfile=shpFile
    csvfile=csvFile

    #Open files
    csvfile=open(csvfile,'wb')
    ds=ogr.Open(shpfile)
    lyr=ds.GetLayer()

    #Get field names
    dfn=lyr.GetLayerDefn()
    nfields=dfn.GetFieldCount()
    fields=[]
    for i in range(nfields):
        fields.append(dfn.GetFieldDefn(i).GetName())
    fields.append('kmlgeometry')
    csvwriter = csv.DictWriter(csvfile, fields, delimiter='|')
    try:csvwriter.writeheader() #python 2.7+
    except:csvfile.write(','.join(fields)+'\n')

    # Write attributes and kml out to csv
    for feat in lyr:
        attributes=feat.items()
        geom=feat.GetGeometryRef()
        #attributes['kmlgeometry']=geom.ExportToKML()
        attributes['kmlgeometry']=geom.ExportToWkt()
        csvwriter.writerow(attributes)

    #clean up
    del csvwriter,lyr,ds
    csvfile.close()

if __name__ == '__main__':
    if not main(sys.argv):
        sys.exit(1)
    else:
        sys.exit(0)
