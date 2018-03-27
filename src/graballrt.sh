#!/bin/bash

# this script downloads multiple series of zipped patent files
# from reedtech.com, according to the ranges specified in the
# csv file provided as the script's only compulsary argument
# for each range, zipped files are downloaded into its subdirectory
# the optional -m parameter gives the maximum number of parallel downloads
# the default is 20

dl_pid=0

function stop_rtdl()
{
    echo "$(basename $0): (PID $$) received a stop signal.."
    if [ $dl_pid -gt 0 ]; then
        echo "$(basename $0): sending HUP to downloader (PID $dl_pid)"
        kill -HUP $dl_pid
    else
        echo "$(basename $0): no downloader running - stopped download of sets at $i!"
        break
    fi
}

# on these signals, pass HUP to the child process
trap stop_rtdl INT TERM HUP QUIT

USAGE_STR="Usage: $(basename $0) [-v] [-u base-URL] [-m maxjobs] [-x extract-dir] csvfile"

VERBOSE=0
extractdir=""
maxjobs=20
#baseurl=http://patents.reedtech.com/downloads/pair
baseurl=http://storage.googleapis.com/uspto-pair/applications

while getopts vu:m:x: opt; do
    case "$opt" in
        v) VERBOSE=1
            ;;
        u) baseurl="$OPTARG"
            ;;
        m) maxjobs="$OPTARG"
            ;;
        x) extractdir="$OPTARG"
            ;;
        \?) # unknown flag
            echo >&2 "$USAGE_STR"
            exit 1
            ;;
    esac
done
# get rid of option params
shift $((OPTIND-1))

if [ $# -ne 1 ]; then
    echo >&2 "$USAGE_STR"
    exit 1
fi

csvfile=$1

startranges=( $(cut -d ',' -f1 "$csvfile") )
endranges=( $(cut -d ',' -f2 "$csvfile") )
rangecontains=( $(cut -d ',' -f3 "$csvfile") )

# get the number of ranges (number of array elements) to process
numentries=${#startranges[@]}
echo "$csvfile contains $numentries patent range entries"

# iterate over each index of the arrays
# Note: find the array keys with "${!foo[@]}"
for i in ${!startranges[@]}; do
    echo

    # at times we need to stop further downloading/processing
    # (due to full filesystem for example)
    # locally this can be done with a kill -HUP (immediate stop),
    # but it's a good idea # to be able to stop processing the next patent series
    # from this or another location when using a network file system
    # look for a stop.graballrt file and quit if there is one
    if [ -e "stop.graballrt" ]; then
        echo "found stop.graballrt.. exiting!"
        echo "please remove stop.graballrt prior to running again."
        echo
        break
    fi

    if [[ "${startranges[$i]}" =~ ^[^0-9]+ ]]; then
        echo "Set $i lacks a valid start range! skipping..."
        continue
    fi

    rangesize=$(seq ${startranges[$i]} ${endranges[$i]} | wc -l)
    echo "processing set $i: ${startranges[$i]} - ${endranges[$i]}, size: $rangesize, containing: ${rangecontains[$i]} archives"

    directory="${startranges[$i]}-${endranges[$i]}"

    if [ -f "${directory}.completed.txt" ]; then
        echo "Set $i in directory $directory has already been processed!"
        echo "(Delete ${directory}.completed.txt to reprocess.)"
        echo "skipping..."
        continue
    fi

    if [ ! -d "$directory" ]; then
        mkdir "$directory" || exit 1
    fi

    if [ ! -f "${directory}.downloaded.txt" ]; then
        if [ $VERBOSE -eq 1 ]; then
            ./rtdl.sh -v -u "$baseurl" -d "$directory" -m $maxjobs ${startranges[$i]} ${endranges[$i]} &
        else
            ./rtdl.sh -u "$baseurl" -d "$directory" -m $maxjobs ${startranges[$i]} ${endranges[$i]} &
        fi

        dl_pid=$!
        echo "waiting for download of set $i to finish..."
        wait $dl_pid
        # if we got interrupted during downloads, don't process any more sets
        if [ $? -gt 0 ]; then
            dl_pid=0
            echo "$(basename $0): warning - interrupted during downloads.. ceasing further downloads!"
            wait # wait for current downloads to complete
            echo "$(basename $0): exiting!"
            echo
            break
        fi
        dl_pid=0

        download_size=$(du -sh "$directory" 2> /dev/null | awk '{ print $1}')
        # ls -f is faster than ls -l (doesn't sort or stat), but enables -a
        downloaded=$(ls -f "$directory" 2> /dev/null | wc -l)
        let downloaded=downloaded-2 # minus . and .. directories

        # check if downloaded archives matches specified number
        if [ $downloaded -ne ${rangecontains[$i]} ]; then
            echo "Warning: downloaded count ($downloaded) doesn't match expected (${rangecontains[$i]})"
        fi

        echo "set $directory: size: $download_size; download count: $downloaded; expected: ${rangecontains[$i]}" > ${directory}.downloaded.txt
    else
        downloaded=$(ls -f "$directory" 2> /dev/null | wc -l)
        let downloaded=downloaded-2 # minus . and .. directories
        echo "Set $i in directory $directory has already been downloaded (contains $downloaded of ${rangecontains[$i]} expected patents)!"
        echo "(Delete ${directory}.downloaded.txt to download any missing patents)"
        echo "skipping..."
    fi

    # extract the metadata from the zipped files in the series
    if [ -n "$extractdir" ]; then
        # create extraction directory if it doesn't already exist
        if [ ! -d "$extractdir" ]; then
            mkdir "$extractdir" || exit 1
        fi

        echo "extracting metadata from zipped files in series..."
        ./unpackrt.sh -z $directory $extractdir
        if [ $? -eq 0 ]; then
            echo "finished extracting metadata and compressing into zipfile: $extractdir/tsv_${directory}.zip"
            echo "metadata extracted from $downloaded patent archives and zipped into $extractdir/tsv_${directory}.zip" > ${directory}.completed.txt
        else
            echo "failed to create metadata zipfile: $extractdir/tsv_${directory}.zip"
        fi
    fi

done

