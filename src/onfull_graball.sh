#!/bin/bash

# Note: this must be run in the same directory as the downloads

USAGE_STR="Usage: $(basename $0) (stop | delete | kill) DISK THRESHOLD"
if [ $# -ne 3 ]; then
    echo >&2 "$USAGE_STR"
    exit 1
fi

action=$1
disk=$2
threshold=$3

dwarn=$(df -P |  awk -v thresh="$threshold" -v disk="$disk" '
    $0 ~ disk {
         n=split($5, use, "%")
         if (use[1]>thresh) {
             printf("Filesystem %s has exceeded threshold %d% at %d%\n", $1, thresh, use[1])
         }
    }')


if [ -n "$dwarn" ]; then

    case "$action" in

        # stop further patent series downloads
        stop)
        echo "stopping further patent series downloads..."
        touch stop.graballrt
        echo "done!"
        ;;

        # delete oldest completed set of downloads
        delete)
        # if there is currently a delete going on - don't do anything
        if [ -e "delete.graballrt" ]; then
            exit 0
        else
        touch delete.graballrt
        fi
        completed=($(ls -tr *.completed.txt)) 2>&1
        oldest=""
        if [ $? -eq 0 ]; then
            #oldest=${completed[0]%.completed.txt}
            for pset in ${completed[@]}; do
                pdir=${pset%.completed.txt} 
                # already cleaned up sets won't have a downloads directory
                if [ -d "$pdir" ]; then 
                    oldest=$pdir
                    echo "deleting downloads directory for oldest set $oldest"
                    /bin/rm -rf $oldest
                    echo "done!"
                    break
                fi
            done
        fi
        /bin/rm -f delete.graballrt
        # this can cause race conditions
        #if [ -z "$oldest" ]; then
        #    # haven't finished any sets - stop further downloads for now
        #    echo "no completed patent series!"
        #    echo "stopping further patent series downloads..."
        #    touch stop.graballrt
        #    echo "done!"
        #fi
        ;;

        # kill downloader process (only works on server running processes)
        kill)
        pids=`ps ux | grep graballrt | grep -v grep | awk '{ print $2 }'`
        if [ -n "$pids" ]; then
            echo "terminating graballrt.sh process..."
            kill -TERM $pids
            echo "done!"
        else
            echo "unable to terminate! no running graballrt.sh process on $(hostname)!"
        fi
        ;;

        *)
        echo "unknown action: $action!"
        exit 1
        ;;
    esac

fi

