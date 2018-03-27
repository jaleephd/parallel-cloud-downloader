#!/bin/bash

# this script downloads a series of zipped patent files from reedtech.com
# Usage: rtdl [-v] [-u base-URL] [-s suffix] [-d directory] [-m maxjobs] first [last]

QUIT_DL=""

function halt_dls()
{
    echo "$(basename $0): (PID $$) received a stop signal.."
    echo "$(basename $0): waiting for current downloads to complete..."
    QUIT_DL="y"
}

# handle interrupts to gracefully exit - complete current downloads only
trap "halt_dls" INT TERM HUP QUIT


USAGE_STR="Usage: $(basename $0) [-v] [-u base-URL] [-s suffix] [-d directory] [-m maxjobs] first [last]"

VERBOSE=0
MAXJOBS=20
baseurl=http://patents.reedtech.com/downloads/pair
#baseurl=http://storage.googleapis.com/uspto-pair/applications
directory="."
suffix=".zip"

while getopts vu:s:d:m: opt; do
    case "$opt" in
        v) VERBOSE=1
            ;;
        u) baseurl="$OPTARG"
            ;;
        d) directory="$OPTARG"
            ;;
        s) suffix="$OPTARG"
            ;;
        m) MAXJOBS="$OPTARG"
            ;;
        \?) # unknown flag
            echo >&2 "$USAGE_STR"
            exit 1
            ;;
    esac
done
# get rid of option params
shift $((OPTIND-1))

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo >&2 "$USAGE_STR"
    exit 1
fi

first=$1
last=$1
step=1
if [ $# -gt 1 ]; then
    last=$2
fi

# note the -w arg zero-pads the generated numbers
files=$(seq -w $first $step $last)
urlcount=$(seq $first $step $last | wc -l)

echo "downloading patent archives ($suffix) from $baseurl into $directory"
echo "querying $urlcount URLs: start $first, end $last, parallelism $MAXJOBS"

let i=0
# ls -f is faster than ls -l (doesn't sort or stat), but enables -a so . .. show
startcnt=$(ls -f ${directory} 2> /dev/null | wc -l)
let startcnt=startcnt-2 # minus . and .. directories
for f in $files; do
    let i=$i+1
    if [ $VERBOSE -eq 1 ]; then
        ./get_rt_archive.sh -v "$baseurl" "${directory}" "${f}" "${suffix}" $i $urlcount &
    else
        ./get_rt_archive.sh "$baseurl" "${directory}" "${f}" "${suffix}" $i $urlcount &
    fi
    # Count the number of jobs running (this job + download jobs)
    njobs=$(jobs -p | wc -l)
    while [ $njobs -gt $MAXJOBS ]; do
        # wait for 500 ms before checking again
        sleep 0.5
        njobs=$(jobs -p | wc -l)
    done
    # if got a stop signal then don't download any more files
    if [ "$QUIT_DL" = "y" ]; then
        break
    fi
done

# wait for all the jobs to finish
wait

# ls -f is faster than ls -l (doesn't sort or stat), but enables -a so . .. show
endcnt=$(ls -f ${directory} 2> /dev/null | wc -l)
let endcnt=endcnt-2 # minus . and .. directories
let downloadcnt=endcnt-startcnt

if [ "$QUIT_DL" = "y" ]; then
    echo "$(basename $0): download of patents in range $first to $last interrupted!"
    echo "$(basename $0): received $downloadcnt files from $urlcount queries, $filecnt files in directory"
    echo "$(basename $0): exiting!"
    exit 1
else
    echo "download of patents in range $first to $last complete!"
    echo "received $downloadcnt files from $urlcount queries, $endcnt files in directory"
    exit 0
fi


