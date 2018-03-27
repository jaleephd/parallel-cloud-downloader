MAILTO=""
PATH=/usr/local/bin:/usr/bin:/bin

# patent sets are generally between 700G and 900G, but can be as low as 500G
# we must keep disk usage under 80% so kill download on slaves if get close
# 75% of 3.9T disk is 2.925T which is at least 3 completed patent sets

#  m  h  dom mon dow   command
*/10  *   *   *   *    (cd /data1/PAIR; ./onfull_graball.sh kill /data1 75)

