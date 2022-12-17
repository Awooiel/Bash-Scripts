#!/bin/bash
# Plot Directory
origin=/mnt/user/chia-storage/PortablePlots
# Plot Final Destination
movetarget=/mnt/remote/write/
# How many Sub folders?
folderc=16
# Folder names?
foldern=files
# Start a new move operation after completion (True-False)
repeat=True
# Time to wait before starting next move operation (Seconds)
rtime=60

runCreate() {
    count=1
    while [ $count -le ${folderc} ]; do
        if [ $count -le 9 ]; then
            [ ! -d "${movetarget}${foldern}0${count}" ] && mkdir -p ${movetarget}${foldern}0${count} 2>/dev/null && echo "${movetarget}${foldern}0${count} Missing, has been Created"
        else
            [ ! -d "${movetarget}${foldern}${count}" ] && mkdir -p ${movetarget}${foldern}${count} 2>/dev/null && echo "${movetarget}${foldern}${count} Missing, has been Created"
        fi
        count=$(($count + 1))
    done
}

runRSync() {
    echo "----------> Starting RSync file round-robin move instance <----------"
    count=1
    while [ $count -le ${folderc} ]; do
        i1=$(find ${origin}/*.plot -type f -printf '%p\n' | sort | head -n 1)
        if [ "$i1" = "error" ] || [ -z "$i1" ]; then
            echo "No Plots to Upload, waiting 60 seconds"
            sleep 60
        else
            if [ $count -le 9 ]; then
                rsync --preallocate --remove-source-files --skip-compress plot --whole-file ${i1} ${movetarget}${foldern}0${count}
            else
                rsync --preallocate --remove-source-files --skip-compress plot --whole-file ${i1} ${movetarget}${foldern}${count}
            fi
            count=$(($count + 1))
        fi
        i1=$(echo error)
    done
}

init() {
    start() {
        runCreate
        runRSync
    }
    start
    if [ "$repeat" = "True" ]; then
        echo "Waiting $rtime seconds before starting next move operation"
        sleep $rtime
        init
    else
        echo "Move Completed, repeat disabled, Goodbye!"
        exit
    fi
}
init
