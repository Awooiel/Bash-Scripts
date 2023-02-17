#!/bin/bash
# Directory Check
origin=/mnt/disks/chia/01/read/
# VFS Location? (Do not include metadata)
vfs=/mnt/disks/z-rcache/VFS/vfs/
# How many RClone folders?
folderc=64
# Folder names?
foldern=files
# Cache files in VFS cache? (Will take some time)
cachesys=False
# File trimmer --- WARNING DELETES FILES ---
filetrim=False
# Trim folders down to file count? --- WARNING DELETES FILES ---
cutfiles=150
# Start a new move operation after completion (True-False)
repeat=True
# Time to wait before starting next scan operation (Seconds)
rtime=14400
# Discord functionality enabled?
discordEnabled=False
# Ping user when there is an issue detected
discordNotify=True
# Discord user to ping (User ID)
discordUserID=""
# Notify when folder wait time is greater than (seconds)
waitMonitor=30
# Discord web hook url
discordHook=""

notifysys() {
    curl -sH "Content-Type: application/json" -X POST -d "{\"content\": \"${dmessage}\"}" ${discordHook}
    if [ ${filec} = 0 ]; then
        dmessage=$(echo "(folder${count}) Access error! Please investigate <@${discordUserID}>!")
        curl -sH "Content-Type: application/json" -X POST -d "{\"content\": \"${dmessage}\"}" ${discordHook}
    elif [ ${runtime} -ge ${waitMonitor} ] && [ ${cachesys} = False ]; then
        dmessage=$(echo "(folder${count}) API Slow! Please investigate <@${discordUserID}>!")
        curl -sH "Content-Type: application/json" -X POST -d "{\"content\": \"${dmessage}\"}" ${discordHook}
    fi
}

runMV() {
    echo "----------> Starting file VFS scan/load <----------"
    count=1
    filect=0
    while [ ${count} -le ${folderc} ]; do
        sleep 15
        echo "Checking.."
        if [ ${cachesys} = True ]; then
            echo "This may take a while. Please wait."
        fi
        start=$(date +%s)
        if [ ${count} -le 9 ]; then
            ls -lah ${origin}${foldern}0${count} 1>/dev/null
            filec=$(ls ${origin}${foldern}0${count} | wc -l 2>/dev/null)
            method="scan"
            if [ ${cachesys} = True ]; then
                echo "Caching ${origin}${foldern}0${count}/*"
                head ${origin}${foldern}0${count}/* -n 1 1>/dev/null
                method="scan and cache"
            elif [ ${filetrim} = True ]; then
                echo "WARNING CLEANER IS RUNNING, CONTAINS ${filec}"
                deletenum=$((${filec} - ${cutfiles}))

                if [ ${deletenum} -ge 1 ]; then
                    delfilesnum=${deletenum}
                    echo "This is ${deletenum} above the allowed size. Deleting extra files now"
                    while [ ${delfilesnum} -ge 1 ]; do
                        plotrm1=$(find ${origin}${foldern}0${count} -name '*.plot' -type f -printf '%p\n' | sort | head -n 1)
                        echo Deleting "${plotrm1}"
                        rm ${plotrm1}
                        delfilesnum=$((${delfilesnum} - 1))
                        echo "There are ${delfilesnum} files left in queue for deletion."
                    done
                    filec=$(ls ${origin}${foldern}0${count} | wc -l 2>/dev/null)
                    echo "Done deleting extra files new file count is ${filec}."
                else

                    echo "There is no need to clean files from this directory as it is equal to or under the ${cutfiles} files trim limit."
                fi
            fi
        else
            ls -lah ${origin}${foldern}${count} 1>/dev/null
            filec=$(ls ${origin}${foldern}${count} | wc -l 2>/dev/null)
            method="scan"
            if [ ${cachesys} = True ]; then
                echo "Caching ${origin}${foldern}${count}/*"
                head ${origin}${foldern}${count}/* -n 1 1>/dev/null
                method="scan and cache"
            elif [ ${filetrim} = True ]; then
                echo "CLEANER IS RUNNING, CONTAINS ${filec}"
                deletenum=$((${filec} - ${cutfiles}))

                if [ ${deletenum} -ge 1 ]; then
                    delfilesnum=${deletenum}
                    echo "This is ${deletenum} above the allowed size. Deleting extra files now"
                    while [ ${delfilesnum} -ge 1 ]; do
                        plotrm1=$(find ${origin}${foldern}${count} -name '*.plot' -type f -printf '%p\n' | sort | head -n 1)
                        echo Deleting "${plotrm1}"
                        rm ${plotrm1}
                        delfilesnum=$((${delfilesnum} - 1))
                        echo "There are ${delfilesnum} files left in queue for deletion."
                    done
                    echo "Done deleting extra files new file count is ${filec}."
                    filec=$(ls ${origin}${foldern}${count} | wc -l 2>/dev/null)
                else

                    echo "There is no need to clean files from this directory as it is equal to or under the ${cutfiles} files trim limit."
                fi
            fi
        fi
        end=$(date +%s)
        runtime="$((end - start))"
        filect=$((${filect} + ${filec}))
        dmessage=$(echo "-- Took ${runtime} seconds to ${method} (folder${count}). Contains ${filec} files. (Total Scanned so far ${filect}) --")
        echo "${dmessage}"
        if [ ${discordEnabled} = True ]; then
            notifysys
        fi
        count=$((${count} + 1))
    done
    vfscount=$(find ${vfs} -type f | wc -l)
    echo "-- There are ${filect} remote files and ${vfscount} files cached in VFS --"
}

init() {
    start() {
        if [ ${filetrim} = True ]; then
            echo "WARNING CLEANER IS ENABLED. IT WILL DELETE FILES!"
            sleep 10
        fi
        runMV
    }
    start
    if [ "$repeat" = "True" ]; then
        echo "Waiting $rtime seconds before starting next scan operation"
        sleep $rtime
        init
    else
        echo "Check Completed, repeat disabled, Goodbye!"
        exit
    fi
}
init
