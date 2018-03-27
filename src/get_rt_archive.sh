#!/bin/bash

# this script downloads a zipped patent file from a patent archive (reedtech.com)
# Usage: get_rt_archive.sh [-v] baseurl, directory, file, suffix, index, urlcount

# ignore interrupts to ensure current download completes
trap "" INT TERM HUP QUIT

declare -i fail=0

VERBOSE=0
if [ $# -gt 1 ] && [ "$1" = "-v" ]; then
    VERBOSE=1
    shift
fi

if [ $# -lt 6 ]; then
    echo >&2 "$(basename $0) called with incorrect parameters: $@"
    return 0
fi

baseurl=$1
directory=$2
f=$3
suffix=$4
i=$5
urlcount=$6

#echo baseurl=$1 directory=$2 f=$3 suffix=$4 i=$5 urlcount=$6

# ls -f is faster than ls -l (doesn't sort or stat), but enables -a so . .. show
filecnt=$(ls -f ${directory} 2>/dev/null | wc -l)
let filecnt=filecnt-2 # minus . and .. directories

# don't download if already have a valid patent archive
if [ -e "${directory}/${f}${suffix}" ]; then
    # check it's a valid archive
    if [ -n "$(file ${directory}/${f}${suffix} | awk -F: '{ print $2 }' | grep -i archive)" ]; then
        echo "archive ${f}${suffix} already exists.. skipping download..."
        exit $fail
    else
        # clean up non-valid file
        if [ $VERBOSE -eq 1 ]; then
            echo "cleaning up old invalid (non-archive) file ${f}${suffix}"
        fi
        rm -f ${directory}/${f}${suffix}
    fi
fi

if [ $VERBOSE -eq 1 ]; then
    echo "querying url ($i of $urlcount, $filecnt archives in directory) $baseurl/${f}${suffix}"
    #wget -a "${directory}.wget.log" -P "$directory" "$baseurl/${f}${suffix}" &
    curl --retry 3 -o "${directory}/${f}${suffix}" "$baseurl/${f}${suffix}" &
else
    # show progress only
    echo -ne "($i / $urlcount : $filecnt)\r"
    #wget -q -P "$directory" "$baseurl/${f}${suffix}" > /dev/null 2>&1 &
    curl --retry 3 -o "${directory}/${f}${suffix}" "$baseurl/${f}${suffix}" > /dev/null 2>&1 &
fi

# wait for download to finish and get exit code
wait
err_code=$?

# some downloads are just HTML or XML error messages that patent record not found
valid=$(file ${directory}/${f}${suffix} | awk -F: '{ print $2 }' | grep -i archive)
if [ -n "$valid" ]; then
    echo "got archive ${f}${suffix} at query $i of $urlcount"
    exit $fail
fi

# process failed downloads - and delete file if it is not an archive
fail=1
if [ -f ${directory}/${f}${suffix} ]; then
    if [ $VERBOSE -eq 1 ]; then
        echo "deleting invalid (non-archive) file ${f}${suffix}"
    fi

    echo "non-patent archive: $(file ${directory}/${f}${suffix}): received at $(date)" >> ${directory}.errors
    echo >> ${directory}/${f}${suffix} # ensure there's an end of line!
    cat ${directory}/${f}${suffix} >> ${directory}.errors
    rm ${directory}/${f}${suffix}
else
    # http request failed (usually a "404 Not Found" for no such patent zip)
    echo "curl http request fail for ${directory}/${f}${suffix}: with error code $err_code at $(date)" >> ${directory}.errors
fi

exit $fail

