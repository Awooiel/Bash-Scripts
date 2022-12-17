#!/bin/bash
# For checking file access latency on rclone sub folders.

# Directory Check
origin=/mnt/disks/
# How many RClone folders?
folderc=16
# Folder names?
foldern=files
# Start a new move operation after completion (True-False)
repeat=True
# Time to wait before starting next move operation (Seconds)
rtime=60

runMV() {
    echo "----------> Starting LS file latency check <----------"
    count=1
    while [ $count -le ${folderc} ]; do
        sleep 15
        echo "Checking.."
        start=$(date +%s)
        if [ $count -le 9 ]; then
            ls -lah ${origin}${foldern}0${count} 1>/dev/null
            filec=$(ls ${origin}${foldern}0${count} | wc -l 2>/dev/null)
        else
            ls -lah ${origin}${foldern}${count} 1>/dev/null
            filec=$(ls ${origin}${foldern}${count} | wc -l 2>/dev/null)
        fi
        end=$(date +%s)
        runtime="$((end - start))"
        echo "-- Took $runtime seconds to access (folder${count}). Contains ${filec} files --"
        count=$(($count + 1))
    done
}

init() {
    start() {
        runMV
    }
    start
    if [ "$repeat" = "True" ]; then
        echo "Waiting $rtime seconds before starting next check operation"
        sleep $rtime
        init
    else
        echo "Check Completed, repeat disabled, Goodbye!"
        exit
    fi
}
init
