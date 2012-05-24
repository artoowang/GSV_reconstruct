#!/bin/bash

if [ $# -ne 1 ] 
then
    echo "Usage: $0 <image_dir>"
    exit
fi

IMAGE_DIR="$1"

cd $IMAGE_DIR
ls *.jpg | sed -n 's/^\(\([-0-9.]*\)_\([-0-9.]*\).*\.jpg\)$/\1 \2 \3/p'

