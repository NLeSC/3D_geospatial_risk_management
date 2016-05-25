#!/bin/bash

for f in `ls extract`; do d=${f%.*}; echo ${d}; ./gml2shp.py extract/$d.gml outShp/$d.shp; done
