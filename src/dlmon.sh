#/bin/sh

nfiles=$1
if [ -z "$nfiles" ]; then
    nfiles=1
else
    shift
fi

nlines=$1
if [ -z "$nlines" ]; then
    nlines=10
fi

df -h .
LATEST=$(ls -ftr *.errors | tail -${nfiles})
echo
echo -n "watching: "
echo $LATEST
echo

for f in $LATEST; do
    tail -${nlines} $f | grep archive | awk -F: '\
    /patent/ { \
        n=split($2, fields, "."); \
        if (n > 0) { \
            printf("%s\n", substr(fields[1],2)) \
        } \
    }' | tail -1
done

