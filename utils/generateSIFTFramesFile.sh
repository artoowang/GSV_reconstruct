#!/bin/bash

SIFT_AUTO_RESIZE=/hydra/S4/Landmarks3/utils/siftAutoResize.sh

rm -f framesFile

for i in `ls *.jpg`; do
	id=$(echo $i | sed 's/^\(\S*\)\.jpg$/\1/')
	if [ ! -e "$id.key.gz" ]; then
		echo "uname -a; $SIFT_AUTO_RESIZE \"$id.jpg\"; echo $id is complete" >> framesFile
	fi
done

