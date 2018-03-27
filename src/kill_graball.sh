#!/bin/bash

# this script gracefully kills the running graballrt.sh process
# allowing it to complete the current downloads before exiting

PIDS=`ps ux | grep graballrt | grep -v grep | awk '{ print $2 }'`
if [ -n "$PIDS" ]; then
    echo "terminating graballrt.sh process..."
    kill -TERM $PIDS
else
    echo "no running graballrt.sh process!"
fi
 
