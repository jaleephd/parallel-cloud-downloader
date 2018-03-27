#!/bin/bash

USAGE_STR="Usage: $(basename $0) [-z] series-dir dest-dir"
ZIP=0

if [ $# -gt 1 ] && [ "$1" = "-z" ]; then
    ZIP=1
    shift
fi

if [ $# -ne 2 ]; then
    echo >&2 "$USAGE_STR"
    exit 1
fi

seriesdir=$1
series=${seriesdir%/} # strip off trailing / if any from series directory
series=${series##*/} # trim off parent dirs from series directory
destdir=$2

if [ ! -d "$destdir/$series" ]; then
    mkdir -p "$destdir/$series"
fi

for f in "$seriesdir"/*.zip; do
    if [ ! -e "$f" ]; then
        echo "no zip files found in $seriesdir"
        echo "exiting.."
        exit 1
    fi
    echo "extracting tsv files from $f .."
    #unzip -l $f '*.tsv' -x '*-image_file_wrapper*'
    unzip $f '*.tsv' -x '*-image_file_wrapper*' -d "$destdir/$series"
done

if [ $ZIP -eq 1 ]; then
    echo "compressing $destdir/$series"
    # note change into directory so that zip doesn't include destination path
    ( cd "$destdir"; zip -r "tsv_${series}" "${series}")
    if [ -f "$destdir/tsv_${series}.zip" ]; then 
        rm -rf "$destdir/$series"
    else
        echo "failed to create $destdir/tsv_${series}.zip!"
        exit 1
    fi
fi

echo "done!"

