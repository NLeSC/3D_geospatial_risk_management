#!/bin/bash

for f in `ls extract`; do d=${f%.*}; echo ${d}; ogr2ogr -f csv -lco GEOEMTRY=AS_WKT outCsv/$d.csv extract/$d.gml ; done

#Sed commands in case we want to remove double cotes and use | as the atttribute seperator
#sed -i 's/",\(\w\)/"\nclean,\1/g' *.csv
#sed -i 's/,"/,\nmerge"/g' *.csv
#sed -i 's/",/"\nclean,/g' *.csv
#sed -i '/^clean/s/,/|/g' *.csv
#sed -e ':a' -e 'N' -e '$!ba' -i -e 's/\nmerge//g' *.csv
#sed -e ':a' -e 'N' -e '$!ba' -i -e 's/\nclean//g' *.csv
#sed -i 's/"//g' *.csv
#sed -i 's/|false|/0/g' *.csv
#sed -i 's/|true|/1/g' *.csv
