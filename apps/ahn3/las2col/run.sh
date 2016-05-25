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

lasnlesc_path=$las2col_dir
echo "las2col is located at: $lasnlesc_path/bin" >&2
echo ""

IFS=$'\n'
cnt=1
for f in `cat files_name_upper`;
do
    echo $f
    #/scratch/goncalve/NLeSC/pointcloud-benchmark/lasnlesc/bin/las2col -i /scratch/goncalve/data/geo_data/ahn3/tileslaz/$f.LAZ --parse XYZainrcpedM /scratch/goncalve/data/geo_data/ahn3/outs/$f\_out &
    $lasnlesc_path/bin/las2col -i $data_path/$f.LAZ --parse XYZainrcpedM $data_path/../$f\_out &
    cnt=$(expr $cnt + 1)
    if (( $(expr $cnt % 16) == 0 )); then echo "wait"; wait; fi
#echo $cnt
done
wait
