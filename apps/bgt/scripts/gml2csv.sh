#!/bin/bash
set -o errexit
set -o nounset
LOG=/tmp/mylog

##################
function if_error
##################
{
if [[ $? -ne 0 ]]; then # check return code passed to function
print "$1 TIME:$TIME" | tee -a $LOG # if rc > 0 then print error msg and quit
exit $?
fi
}

DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Reading monetdb config..." >&2
. $DIR/../../../configs/monetdb.cfg

scripts=$monetdb_scripts
echo "MonetDB scripts are located at: $scripts" >&2
echo ""

echo "Reading bgt config..." >&2
. $DIR/../../../configs/bgt.cfg

data_path=$bgt_data_path
echo "Output data will be stored at: $data_path" >&2
echo ""

extract_path=$bgt_extract_path
echo "Input data is located at: $data_path" >&2
echo ""

for f in `ls $extract_path`; do d=${f%.*}; echo ${d}; ogr2ogr -f csv -lco GEOEMTRY=AS_WKT $data_path/$d.csv $extract_path/$d.gml ; done

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
