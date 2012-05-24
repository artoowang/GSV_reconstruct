#!/bin/bash

# This script will check if the given directory (if not given, then use current directory)
# is a valid Landmarks3 root directory.

if [ $# -ge 1 ]; then
	cd "$1"
fi

# Check the existence of directory/symbolic links
DIRS="data data_large html logs options sql_db utils webroot"
result=0
for DIR in $DIRS; do
	if [ ! -d "$DIR" ]; then
		echo >&2 "Directory $DIR is not found!"
		result=-1
	fi
done

FILES="base_url.txt"
for FILE in $FILES; do
	if [ ! -r "$FILE" ]; then
		echo >&2 "File $FILE is not found!"
		result=-1
	fi
done

exit $result
