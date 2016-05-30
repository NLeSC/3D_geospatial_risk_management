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

out_path=$ahn3_out_dir
echo "AHN3 binary files are located at: $out_path" >&2
echo ""

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
    echo "create table $f (x decimal(9,3), y decimal(9,3), z decimal(9,3), a tinyint, i smallint, n smallint, r smallint, c tinyint, p smallint, e smallint, d smallint, M int);";
done > "create_tables.sql"
echo "Defining tables done..."

echo "create merge table ahn3 (x decimal(9,3), y decimal(9,3), z decimal(9,3), a tinyint, i smallint, n smallint, r smallint, c tinyint, p smallint, e smallint, d smallint, M int);" > "create_merge_table.sql"
#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "alter table ahn3 add table $f;";
done >> "create_merge_table.sql"
echo "Defining the merge table done..."

echo "drop table ahn3;" > "drop_tables.sql"
#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "drop table $f;";
done >> "drop_tables.sql"
echo "Defining drop tables done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "select '$f', count(*) from $f;";
done > "count_tables.sql"
echo "Defining count tables done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_x_imprints on $f(x);";
done > "build_imprints_x.sql"
echo "Defining buildimprints for column x done.."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_y_imprints on $f(y);";
done > "build_imprints_y.sql"
echo "Defining buildimprints for column y done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_z_imprints on $f(z);";
done > "build_imprints_z.sql"
echo "Defining buildimprints for column z done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_c_imprints on $f(c);";
done > "build_imprints_c.sql"
echo "Defining buildimprints for column c done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_r_imprints on $f(r);";
done > "build_imprints_r.sql"
echo "Defining buildimprints for column r done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_n_imprints on $f(n);";
done > "build_imprints_n.sql"
echo "Defining buildimprints for column n done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "create imprints index $f\_i_imprints on $f(i);";
done > "build_imprints_i.sql"
echo "Defining buildimprints for column i done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "drop index $f\_x_imprints;";
	echo "drop index $f\_y_imprints;";
	echo "drop index $f\_z_imprints;";
	echo "drop index $f\_c_imprints;";
	echo "drop index $f\_r_imprints;";
	echo "drop index $f\_n_imprints;";
	echo "drop index $f\_i_imprints;";
done > "drop_imprints.sql"
echo "Defining drop imprints done..."

echo "Defining buildimprints for column c done..."
#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "alter table $f set read only;";
done > "set_readonly.sql"
echo "Defining set read only done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "analyze sys.$f (x,y,z,c,r,n,i) minmax;";
done > "analyze_tables.sql"
echo "call vacuum('sys', 'statistics');" >> "analyze_tables.sql"
echo "Defining analyze done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "call lidarattach('$data_path/$f.LAZ');";
done > "attach_data.sql"
echo "Defining data attachment done..."

#for f in `ls $data_path | grep -E LAZ | sed 's/\.LAZ//g'`; do
for f in `cat ../las2col/files_name_upper`; do
	echo "copy binary into $f from('$out_path/$f\_out_col_X.dat', '$out_path/$f\_out_col_Y.dat', '$out_path/$f\_out_col_Z.dat', '$out_path/$f\_out_col_a.dat', '$out_path/$f\_out_col_i.dat', '$out_path/$f\_out_col_n.dat', '$out_path/$f\_out_col_r.dat', '$out_path/$f\_out_col_c.dat', '$out_path/$f\_out_col_p.dat', '$out_path/$f\_out_col_e.dat', '$out_path/$f\_out_col_d.dat', '$out_path/$f\_out_col_M.dat');";
done > "load_data.sql"
echo "Defining data load done..."

sed -i 's/\\_/_/g' *.sql

echo ""
echo "The DDLs were generated with success please follow the following steps:"
echo ""
echo ""
echo "---> For DataVaults:"
echo "1. Attach the LAS files: $scripts/mclient optimized sql < attach_data.sql"
echo ""
echo "2. Define the merge table by: $scripts/mclient optimized sql < create_merge_table.sql"
echo ""
echo ""
echo "---> For BinaryAttachment:"
echo "1. Create tables: $scripts/mclient optimized sql < create_tables.sql"
echo ""
echo "2. Define the merge table by: $scripts/mclient optimized sql < create_merge_table.sql"
echo ""
echo "3. Load data into tables: $scripts/mclient optimized sql < load_data.sql"
echo ""
echo "4. Set read only: $scripts/mclient optimized sql < set_readonly.sql"
echo ""
echo "5. Build imprints: $scripts/mclient optimized sql < build_imprints_x.sql & $scripts/mclient optimized sql < build_imprints_y.sql & $scripts/mclient optimized sql < build_imprints_z.sql & $scripts/mclient optimized sql < build_imprints_c.sql"
echo ""
echo "6. Analyze tables: $scripts/mclient optimized sql < analyze_tables.sql"
echo ""
