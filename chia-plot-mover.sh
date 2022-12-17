#!/bin/bash
# Plot Directory
origin=/mnt/user/chia-storage/PortablePlots
# Plot Temporary Destination
temptarget=/mnt/remotes/TemporaryPlots
# Use temporary plot destination (To avoid permissions issues that can occur with moving files to remote machines)
tempdir=True
# Plot Final Destination
finaltarget=/mnt/remotes/PortablePlots
# Software used to move Plots (rsync or mv)
software=mv
# How many parellel file move instances do you want? (1-3)
instances=1
# Apply updated permissions to Plot files? (True-False)
permissions=True
# Start a new move operation after completion (True-False)
repeat=True
# Time to wait before starting next move operation (Seconds)
rtime=60

runRsync() {
    if [ $instances = 1 ]; then
        echo "----------> Starting RSync file transfer instance 1 <----------"
        rsync -avh --remove-source-files ${i1} ${movetarget} 2>/dev/null
    elif [ $instances = 2 ]; then
        echo "----------> Starting RSync file transfer instance 1 <----------"
        echo "----------> Starting RSync file transfer instance 2 <----------"
        rsync -avh --remove-source-files ${i1} ${movetarget} 2>/dev/null &
        rsync -avh --remove-source-files ${i2} ${movetarget} 2>/dev/null
    elif [ $instances = 3 ]; then
        echo "----------> Starting RSync file transfer instance 1 <----------"
        echo "----------> Starting RSync file transfer instance 2 <----------"
        echo "----------> Starting RSync file transfer instance 3 <----------"
        rsync -avh --remove-source-files ${i1} ${movetarget} 2>/dev/null &
        rsync -avh --remove-source-files ${i2} ${movetarget} 2>/dev/null &
        rsync -avh --remove-source-files ${i3} ${movetarget} 2>/dev/null
    else
        echo "Invalid Instances Entered (Must be 1-3)"
        exit
    fi
}

runMV() {
    if [ $instances = 1 ]; then
        echo "----------> Starting MV file transfer instance 1 <----------"
        echo "Moving Plot from $i1 to ${movetarget}"
        mv -f ${i1} ${movetarget} 2>/dev/null
    elif [ $instances = 2 ]; then
        echo "----------> Starting MV file transfer instance 1 <----------"
        echo "----------> Starting MV file transfer instance 2 <----------"
        echo "Moving Plot from $i1 to ${movetarget}"
        echo "Moving Plot from $i2 to ${movetarget}"
        mv -f ${i1} ${movetarget} 2>/dev/null &
        mv -f ${i2} ${movetarget} 2>/dev/null
    elif [ $instances = 3 ]; then
        echo "----------> Starting MV file transfer instance 1 <----------"
        echo "----------> Starting MV file transfer instance 2 <----------"
        echo "----------> Starting MV file transfer instance 3 <----------"
        echo "Moving Plot from ${i1} to ${movetarget}"
        echo "Moving Plot from ${i2} to ${movetarget}"
        echo "Moving Plot from ${i3} to ${movetarget}"
        mv -f ${i1} ${movetarget} 2>/dev/null &
        mv -f ${i2} ${movetarget} 2>/dev/null &
        mv -f ${i3} ${movetarget} 2>/dev/null
    else
        echo "Invalid Instances Entered (Must be 1-3)"
        exit
    fi
}

runMove() {
    echo "Moving plots from temporary directory to final directory"
    mv ${temptarget}/${m1} ${finaltarget} 2>/dev/null
    mv ${temptarget}/${m2} ${finaltarget} 2>/dev/null
    mv ${temptarget}/${m3} ${finaltarget} 2>/dev/null
}

errorCheck() {
    errorrun() {
        runtime="$((end - start))"
        echo "Errors occured during move operation, Took ${runtime} seconds to run"
        #        for pid in $(ps -ef | grep "rsync -avhP --remove-source-files" | awk '{print $2}'); do kill -9 $pid 2>/dev/null; done
        #        for pid in $(ps -ef | grep "mv -f" | awk '{print $2}'); do kill -9 $pid 2>/dev/null; done
        if [ "$software" = "rsync" ]; then
            echo "Deleting incomplete files ${movetarget}/.${m1}.*  ${movetarget}/.${m2}.*  ${movetarget}/.${m3}.*"
            rm ${movetarget}/.${m1}.* 2>/dev/null
            rm ${movetarget}/.${m2}.* 2>/dev/null
            rm ${movetarget}/.${m3}.* 2>/dev/null
            echo "Done deleting files"
        elif [ "$software" = "mv" ]; then
            echo "Deleting incomplete files ${movetarget}/${m1}  ${movetarget}/${m2}  ${movetarget}/${m3}"
            rm ${movetarget}/${m1} 2>/dev/null
            rm ${movetarget}/${m2} 2>/dev/null
            rm ${movetarget}/${m3} 2>/dev/null
            echo "Done deleting files"
        fi
    }
    zerocheck() {
        if [ $instances = 1 ]; then
            if [ -z ${e1} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m1} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            fi
        elif [ $instances = 2 ]; then
            if [ -z ${e1} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m1} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            elif [ -z ${e2} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m2} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            fi
        elif [ $instances = 3 ]; then
            if [ -z ${e1} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m1} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            elif [ -z ${e2} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m2} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            elif [ -z ${e3} ]; then
                echo "----------> Couldn't check target file for errors, waiting for file system tasks to complete... <----------"
                echo "${m3} pending, checking again in 5 minutes. Please wait..."
                sleep 300
                errorCheck
            fi
        fi

    }
    if [ $instances = 1 ]; then
        if [ "$software" = "rsync" ]; then
            c1=$(find ${movetarget}/.${m1}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d1=$(echo ${c1} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d1} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${d1} 2>/dev/null)
        elif [ "$software" = "mv" ]; then
            #touch -a ${movetarget}/${m1} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${m1} 2>/dev/null)
        fi
        zerocheck
        if [ $e1 -le 107835882700 ]; then
            errorrun
        else
            runtime="$((end - start))"
            echo "Move completed without errors, took ${runtime} seconds to complete"
        fi
    elif [ $instances = 2 ]; then
        if [ "$software" = "rsync" ]; then
            c1=$(find ${movetarget}/.${m1}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d1=$(echo ${c1} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d1} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${d1} 2>/dev/null)
            c2=$(find ${movetarget}/.${m2}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d2=$(echo ${c2} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d2} 2>/dev/null
            e2=$(stat -c%s ${movetarget}/${d2} 2>/dev/null)
        elif [ "$software" = "mv" ]; then
            #touch -a ${movetarget}/${m1} 2>/dev/null
            #touch -a ${movetarget}/${m2} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${m1} 2>/dev/null)
            e2=$(stat -c%s ${movetarget}/${m2} 2>/dev/null)
        fi
        zerocheck
        if [ $e1 -le 107835882700 ] && [ $e2 -le 107835882700 ]; then
            errorrun
        else
            runtime="$((end - start))"
            echo "Move completed without errors, took $runtime seconds to complete"
        fi
    elif [ $instances = 3 ]; then
        if [ "$software" = "rsync" ]; then
            c1=$(find ${movetarget}/.${m1}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d1=$(echo ${c1} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d1} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${d1} 2>/dev/null)
            c2=$(find ${movetarget}/.${m2}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d2=$(echo ${c2} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d2} 2>/dev/null
            e2=$(stat -c%s ${movetarget}/${d2} 2>/dev/null)
            c3=$(find ${movetarget}/.${m3}.* -type f -printf '%p\n %f\n' | sort | head -n 1)
            d3=$(echo ${c3} | tr -d " \t\n\r")
            #touch -a ${movetarget}/${d3} 2>/dev/null
            e3=$(stat -c%s ${movetarget}/${d3} 2>/dev/null)
        elif [ "$software" = "mv" ]; then
            #touch -a ${movetarget}/${m1} 2>/dev/null
            #touch -a ${movetarget}/${m2} 2>/dev/null
            #touch -a ${movetarget}/${m3} 2>/dev/null
            e1=$(stat -c%s ${movetarget}/${m1} 2>/dev/null)
            e2=$(stat -c%s ${movetarget}/${m2} 2>/dev/null)
            e3=$(stat -c%s ${movetarget}/${m3} 2>/dev/null)
        fi
        zerocheck
        if [ $e1 -le 107835882700 ] && [ $e2 -le 107835882700 ] && [ $e3 -le 107835882700 ]; then
            errorrun
        else
            runtime="$((end - start))"
            echo "Move completed successfully, took $runtime seconds to complete"
        fi
    fi
}

setPermissions() {
    echo "Applying Chia Plot file permissions."
    chown -fR nobody:users $origin 2>/dev/null
    chown -fR nobody:users $movetarget 2>/dev/null
    chmod -fR 666 $origin 2>/dev/null
    chmod -fR 666 $movetarget 2>/dev/null
}

init() {
    start() {
        echo "----------> Initializing <----------"
        #        for pid in $(ps -ef | grep "rsync -avhP --remove-source-files" | awk '{print $2}'); do kill -9 $pid 2>/dev/null; done
        #        for pid in $(ps -ef | grep "mv -f" | awk '{print $2}'); do kill -9 $pid 2>/dev/null; done
        setPermissions
        i1=$(find ${origin}/*.plot -type f -printf '%p\n' | sort | head -n 1)
        i2=$(find ${origin}/*.plot -type f -printf '%p\n' | sort | head -n 2 | tail -n +2)
        i3=$(find ${origin}/*.plot -type f -printf '%p\n' | sort | head -n 3 | tail -n +3)
        l1=$(find ${origin}/*.plot -type f -printf '%p\n %f\n' | sort | head -n 1)
        l2=$(find ${origin}/*.plot -type f -printf '%p\n %f\n' | sort | head -n 2 | tail -n +2)
        l3=$(find ${origin}/*.plot -type f -printf '%p\n %f\n' | sort | head -n 3 | tail -n +3)
        m1=$(echo ${l1} | tr -d " \t\n\r")
        m2=$(echo ${l2} | tr -d " \t\n\r")
        m3=$(echo ${l3} | tr -d " \t\n\r")
        if [ "$tempdir" = "True" ]; then
            movetarget=$temptarget
            if [ -d "$movetarget" ] && [ -d "$finaltarget" ]; then
                echo "Selected $movetarget as the temporary move directory"
                echo "Selected $finaltarget as the target directory"
            else
                echo "$movetarget and/or $finaltarget are not valid accessible directories"
                exit
            fi
        elif [ "$tempdir" = "False" ]; then
            movetarget=$finaltarget
            if [ -d "$movetarget" ]; then
                echo "Selected $movetarget as the target directory"
            else
                echo "$movetarget is not a valid accessible directory"
                exit
            fi
        fi
        start=$(date +%s)
        if [ "$software" = "rsync" ]; then
            runRsync
        elif [ "$software" = "mv" ]; then
            runMV
        else
            echo "Invalid software selected (Option must be set to rsync or mv)"
        fi
        end=$(date +%s)
        errorCheck
        if [ "$tempdir" = "True" ]; then
            runMove
        fi
        if [ "$permissions" = "True" ]; then
            setPermissions
        fi
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
