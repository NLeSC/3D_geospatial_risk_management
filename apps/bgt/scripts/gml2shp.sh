#!/bin/bash

#for f in `ls extract`; do d=${f%.*}; echo ${d}; ./gml2shp.py extract/$d.gml outShp/$d.shp; done
for f in `ls extract`; do d=${f%.*}; echo ${d}; ogr2ogr -f csv -lco GEOEMTRY=AS_WKT outShp/$d.csv extract/$d.gml ; done
