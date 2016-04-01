#!/bin/bash

for f in `ls extract`; do d=${f%.*}; echo ${d}; ./shp2csv.py outShp/$d.shp outCsv/$d.csv; done
