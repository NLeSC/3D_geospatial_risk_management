#!/bin/bash
set -o errexit
set -o nounset
LOG=/tmp/mylog

##################
function if_error
##################
{
    if [[ $? -ne 0 ]]; then # check return code passed to function
        echo "$1 TIME:$TIME" | tee -a $LOG # if rc > 0 then print error msg and quit
        exit $?
    fi
}

echo "Run config" >&2
. ../config/config.sh
if_error "The config failed!!!"

echo "Run gml2shp" >&2
python gml2shp.py test_data/bgt_tunnelpart.gml test_data/bgt_tunnelpart.shp &&
if_error "gml2shp failed!!!"

echo "Run shp2csv" >&2
python shp2csv.py test_data/bgt_tunnelpart.shp test_data/bgt_tunnelpart.csv &&
if_error "shp2csv failed!!!"

echo "Remove intermediate files" >&2
rm test_data/bgt_tunnelpart.gfs test_data/bgt_tunnelpart.dbf test_data/bgt_tunnelpart.prj test_data/bgt_tunnelpart.shp test_data/bgt_tunnelpart.shx
