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

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
    echo "create table $f (x decimal(9,3), y decimal(9,3), z decimal(9,3), a tinyint, i smallint, n smallint, r smallint, c tinyint, p smallint, e smallint, d smallint, M int);";
done > "create_tables.sql"
echo "Defining the merge table done..."

echo "create merge table ahn3 (x decimal(9,3), y decimal(9,3), z decimal(9,3), a tinyint, i smallint, n smallint, r smallint, c tinyint, p smallint, e smallint, d smallint, M int);" > "create_merge_table.sql"
for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "alter table ahn3 add table $f;";
done >> "create_merge_table.sql"
echo "Defining the merge table done..."

echo "drop table ahn3;" > "drop_tables.sql"
for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "drop table $f;";
done >> "drop_tables.sql"
echo "Defining drop tables done..."

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "select '$f', count(*) from $f;";
done > "count_tables.sql"
echo "Defining count tables done..."

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "alter table $f set read only;";
done > "set_readonlys.sql"
echo "Defining iset read only done..."

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "call lidarattach('$data_path/$f.LAZ');";
done > "attach_data.sql"
echo "Defining data attachment done..."

for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
	echo "copy binary into $f from('$data_path/../outs/$f\_out_col_X.dat', '$data_path/../outs/$f\_out_col_Y.dat', '$data_path/../outs/$f\_out_col_Z.dat', '$data_path/../outs/$f\_out_col_a.dat', '$data_path/../outs/$f\_out_col_i.dat', '$data_path/../outs/$f\_out_col_n.dat', '$data_path/../outs/$f\_out_col_r.dat', '$data_path/../outs/$f\_out_col_c.dat', '$data_path/../outs/$f\_out_col_p.dat', '$data_path/../outs/$f\_out_col_e.dat', '$data_path/../outs/$f\_out_col_d.dat', '$data_path/../outs/$f\_out_col_M.dat');";
done > "load_data.sql"
echo "Defining data attachment done..."

sed -i 's/\\_out/_out/g' load_data.sql

echo ""
echo "The DDLs were generated with success please follow the following steps:"
echo "1. Attach the LAS files: $scripts/mclient optimized sql < attach_data.sql"
echo ""
echo "2. Define the merge table by: $scripts/mclient optimized sql < create_merge_table.sql"
echo ""
