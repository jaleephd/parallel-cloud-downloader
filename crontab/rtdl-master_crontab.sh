MAILTO=""
PATH=/usr/local/bin:/usr/bin:/bin

# patent sets are generally between 700G and 900G, but can be as low as 500G
# 45% of 3.9T disk is 1.7T which is 2-3 patent sets
# this allows at least one of the rtdl slaves to have completed a series
# and started a new series before cleaning up oldest finished series
# to clear disk space for further downloads

#  m  h  dom mon dow   command
*/10  *   *   *   *    (cd /data1/PAIR; ./onfull_graball.sh delete /data1 45)

