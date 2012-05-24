#!/bin/bash

function usage () {
	echo >&2 "Usage: findGSV_CIDs.sh <list_file>"
	exit -1
}

if [ $# -ne 1 ]; then usage; fi

LISTFILE_PATH="$1"

if [ ! -e "$LISTFILE_PATH" ]; then
	echo >&2 "$LISTFILE_PATH not found"
	exit -1
fi

# Here CID has two meanings: (1) component ID (2) camera ID (in list file, 1-based)

# Find the camera IDs of the photos in the list file that are GSV images
LINES=$(/bin/egrep -n "/[0-9.-]+_[0-9.-]+_[0-9.-]+_[0-9.-]+.jpg" "$LISTFILE_PATH" | sed -n 's/^\([0-9]*\):.*/\1/p')
CID_START=$(/bin/echo "$LINES" | head -1)
CID_END=$(/bin/echo "$LINES" | tail -1)

if [ -z "$CID_START"  -o  -z "$CID_END" ]; then
	echo >&2 "No GSV image found"
	exit -1
fi

echo "$CID_START:$CID_END"
exit 0
