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
echo "Reading ahn3 config..." >&2
. $DIR/../../configs/ahn3.cfg

ahn3_dir=$ahn3_data_dir
echo "The AHN3 will stored at: $ahn3_dir" >&2
echo ""

IFS=$'\n'
cnt=1
for f in $(<files_upper);
do
    wget --directory-prefix=$ahn3_dir $f &
    cnt=$(expr $cnt + 1)
    if (( $(expr $cnt % 32) == 0 )); then echo "wait"; wait; fi
    #echo $cnt
done
wait

echo "The AHN3 files were successufly downloaded and they are located at : $ahn3_dir" >&2
