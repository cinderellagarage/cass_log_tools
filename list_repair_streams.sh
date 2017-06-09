#!/bin/sh

# Lists all logged incoming and outgoing repair streams including
# number of keys and size streamed to and from node.
#
# Defaults to listing incoming strings.
# Use `./list_repair_streams.sh outgoing` to see outgoing streams
#
# Only works with DSE 5.0+ with included debug.log files.
#
# Author Brad Vernon, 2017 June 9 - Initial Release


pwd=`pwd`
dir_name=`basename $pwd`
if [ "$dir_name" != "nodes" ]
then
    echo "ERROR - Script must be run in the [nodes] directory of the diagnostics report"
    exit 1
fi

LIST_SYSTEM_FILES=($(find . -type f -name 'debug.log'))

if [ ${#LIST_SYSTEM_FILES[@]} -eq 0 ]; then
    echo "ERROR: Script only works with DSE 5.0+"
    exit 1
fi

FORMAT1="%-20s%-30s%-15s%-15s%-20s%-20s\n"
FORMAT2="%-20s%-30s%-15s%-15.2f%-20s%-20s\n"
BEGIN="BEGIN{printf(\"$FORMAT1\",\"Node\",\"Time\",\"Keys\",\"Size(mb)\",\"Keyspace\",\"Table\")}"
BEGIN2="BEGIN{printf(\"$FORMAT1\",\"Node\",\"Time\",\"Keys\",\"Size(mb)\",\"SSTable\",\"\")}"

if [ "${1}x" == "x" ] || [ "${1}" == "incoming" ]; then
    for i in "${LIST_SYSTEM_FILES[@]}"
    do
        echo $i | awk -F"/" '{print "\n\nRepair Streams Incoming for Node IP "$2":\n"}'

        grep "Received File" $i | awk '{print $2"|"$3,$4"|"$21"|"$24"|"$32}' | \
        perl -p -e 's/\[STREAM-IN-\/(.*):.*\]\|(.*)\|(.*),\|(.*),\|(.*)\/(.*)\)/$1|$2|$3|$4|$5|$6/g' | \
        awk -F"|" ''$BEGIN' {printf "'$FORMAT2'",$1,$2,$3,$4/1024/1024,$5,$6,$7}'

    done
fi

if [ "${1}" == "outgoing" ]; then
    for i in "${LIST_SYSTEM_FILES[@]}"
    do
        echo $i | awk -F"/" '{print "\n\nRepair Streams Outgoing for Node IP "$2":\n"}'

        grep "Sending File" $i | awk '{print $2"|"$3,$4"|"$21"|"$24"|"$32}' | \
        perl -p -e 's/\[STREAM-OUT-\/(.*):.*\]\|(.*)\|(.*),\|(.*),\|(.*)\/(.*)\)/$1|$2|$3|$4|$5|$6/g' | \
        awk -F"|" ''$BEGIN2' {printf "'$FORMAT2'",$1,$2,$3,$4/1024/1024,$5,$6,$7}'

    done
fi
