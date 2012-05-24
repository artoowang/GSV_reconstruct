#!/bin/bash

if [ $# -ne 1 ] 
then
    echo "Usage: $0 <image_dir>"
    exit
fi

IMAGE_DIR="$1"
FOCAL_LEN=502.363438	# For Google Street View images downloaded by utils/GSVdownloader/streetview_download.m

for img in $(ls "$IMAGE_DIR"/*.jpg); do
	echo "$img 0 $FOCAL_LEN"
done

