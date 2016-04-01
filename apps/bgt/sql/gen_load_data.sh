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
echo "Input data is located at: $data_path" >&2
echo ""

ls $data_path/*.csv > "data_files.txt"

while read -r a && read -r file <&3; do 
	echo "$a$file') USING DELIMITERS '|','\n' NULL AS '' LOCKED;"
done < "load_data.tmp" 3< "data_files.txt" > load_data.sql

rm "data_files.txt"
echo "The load_data.sql is generated. To load it run: $scripts/mclient optimized sql < load_data.sql"
