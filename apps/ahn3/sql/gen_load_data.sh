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

echo "Reading ahn3 config..." >&2
. $DIR/../../../configs/ahn3.cfg

data_path=$ahn3_data_dir
echo "AHN3 LAS/LAZ files are located at: $data_path" >&2
echo ""

echo "create merge table ahn3 (x decimal(9,3), y decimal(9,3), z decimal(9,3), a int, i int, n int, r int, c int, p int, e int, d int, M int);" > "create_merge_table.sql"
for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "alter table ahn3 add table $f;";
done >> "create_merge_table.sql"
echo "Defining the merge table done..."

echo "drop table ahn3;"
for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "drop table $f;";
done >> "drop_tables.sql"
echo "Defining drop tables done..."

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "call lidarattach('$data_path/$f.LAZ');";
done > "attach_data.sql"
echo "Defining data attachment done..."

echo ""
echo "The DDLs were generated with success please follow the following steps:"
echo "1. Attach the LAS files: $scripts/mclient optimized sql < attach_data.sql"
echo ""
echo "2. Define the merge table by: $scripts/mclient optimized sql < create_merge_table.sql"
echo ""
