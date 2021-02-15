#!/bin/bash

# This script will calculate the IP path MTU for all BTS in a network.
# This script will take CSV file as input containing the Site ID and mPlane IP.
# Output will be stored in a file path_mtu_output.csv in the same directory.

INPUT=mPlane_IP.csv
OUTPUT=path_mtu_output.csv
OLDIFS=$IFS
IFS=','


function path_mtu_finder(){
    ip_addr=$1

    local success=0
    local fail=65500
    local is_65500_flag=0
    local s=$fail

    while [ $(( fail - success )) -ne 1 ]
    do
        ping -c 1 -s $s $ip_addr
        if [ $? -eq 0 ]
        then
            success=$s
            if [ $is_65500_flag -eq 0 ]
            then
                break
            fi
        else
            fail=$s
        fi
        s=$(( success + ( fail - success ) / 2 ))
        is_65500_flag=1
    done

    path_mtu=$success

}


echo "PATH MTU discovery script starting with PID $$"
[ ! -f $INPUT ] && { echo "$INPUT file not found"; IFS=$OLDIFS; exit 99; }
[ -f $OUTPUT ] && truncate -s 0 $OUTPUT
echo 'MRBTS ID,MRBTS IP,PATH MTU'>>$OUTPUT

while read mrbts_id mPlane_IP
do
	echo "$mrbts_id and $mPlane_IP"

    ping -c 1 -s 0 $mPlane_IP 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]
    then
        echo "$mrbts_id,$mPlane_IP,O&M Down">>$OUTPUT
        continue
    fi

    path_mtu_finder $mPlane_IP
    echo "$mrbts_id,$mPlane_IP,$path_mtu">>$OUTPUT

done < $INPUT

echo "Script Finished."
