#!/bin/bash
#RClone access mode (read/write) (Optimizes rclone mount config for reading or writing files)
accessm=read
# RClone remote
remoten=dropbox
# RClone remote folder name?
remotefn=Media

# ----- Access mode read specific options -----
# Sub folder names? (read)
subfn=files
# RClone local mount location (read)
mountl=/mnt/disks/dropbox/01/read/
# RClone local cache location (read)
cachel=/mnt/applications/appdata/RClone-Cache/Dropbox/
# RClone local cache max size (read)
cachesz=950G
# RClone local cache max age (read)
agec=99999999999h
# RClone chunk size (read)
chunksz=64K
# How many RClone sub folders? (read)
subfc=16

# ----- Access mode write specific options -----
# RClone local mount location (write)
mountw=/mnt/disks/dropbox/01/write/
# RClone local cache location (write)
cachelw=/mnt/user/Cache/
# RClone local cache max size (write)
cacheszw=11000G
# RClone max uploads at once (write)
transferc=8
# RClone max file checkers at once (write)
checkerc=12
# RClone bandwidth limit (write) (max allowed upload speed MB/s)
uploadsd=50M

runMount() {
    echo "----------> Mounting RClone filesystem(s) <----------"
    count=1
    if [ ${accessm} = read ]; then
        while [ ${count} -le ${subfc} ]; do
            if [ ${count} = ${subfc} ]; then
                if [ $count -le 9 ]; then
                    mkdir -p ${mountl}${subfn}0${count}
                    rclone mount --allow-other ${remoten}:${remotefn}/${subfn}0${count} ${mountl}${subfn}0${count} --cache-dir "${cachel}" --multi-thread-streams 1024 --multi-thread-cutoff 128M --network-mode --vfs-cache-mode full --vfs-cache-max-size ${cachesz} --vfs-cache-max-age ${agec} --vfs-read-chunk-size-limit off --buffer-size 0K --vfs-read-chunk-size ${chunksz} --vfs-read-wait 0ms -v
                else
                    mkdir -p ${mountl}${subfn}${count}
                    rclone mount --allow-other ${remoten}:${remotefn}/${subfn}${count} ${mountl}${subfn}${count} --cache-dir "${cachel}" --multi-thread-streams 1024 --multi-thread-cutoff 128M --network-mode --vfs-cache-mode full --vfs-cache-max-size ${cachesz} --vfs-cache-max-age ${agec} --vfs-read-chunk-size-limit off --buffer-size 0K --vfs-read-chunk-size ${chunksz} --vfs-read-wait 0ms -v
                fi
            elif [ $count -le 9 ]; then
                mkdir -p ${mountl}${subfn}0${count}
                rclone mount --allow-other ${remoten}:${remotefn}/${subfn}0${count} ${mountl}${subfn}0${count} --cache-dir "${cachel}" --multi-thread-streams 1024 --multi-thread-cutoff 128M --network-mode --vfs-cache-mode full --vfs-cache-max-size ${cachesz} --vfs-cache-max-age ${agec} --vfs-read-chunk-size-limit off --buffer-size 0K --vfs-read-chunk-size ${chunksz} --vfs-read-wait 0ms -v &
            else
                mkdir -p ${mountl}${subfn}${count}
                rclone mount --allow-other ${remoten}:${remotefn}/${subfn}${count} ${mountl}${subfn}${count} --cache-dir "${cachel}" --multi-thread-streams 1024 --multi-thread-cutoff 128M --network-mode --vfs-cache-mode full --vfs-cache-max-size ${cachesz} --vfs-cache-max-age ${agec} --vfs-read-chunk-size-limit off --buffer-size 0K --vfs-read-chunk-size ${chunksz} --vfs-read-wait 0ms -v &
            fi
            count=$(($count + 1))
        done
    elif [ ${accessm} = write ]; then
        mkdir -p ${mountw}
        rclone mount --allow-other ${remoten}:${remotefn}/ ${mountw} --cache-dir "${cachelw}" --multi-thread-streams 1024 --multi-thread-cutoff 128M --network-mode --vfs-cache-mode minimal --vfs-cache-max-size ${cacheszw} --drive-chunk-size 4096M --max-backlog=999999 --transfers=${transferc} --checkers=${checkerc} --bwlimit ${uploadsd} --buffer-size 1024M -v
    else
        echo "Invalid access mode please use read or write"
    fi
}

init() {
    start() {
        runMount
    }
    start
}
init
