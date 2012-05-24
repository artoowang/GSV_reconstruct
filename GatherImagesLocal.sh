#!/bin/bash

# This script assumes it executed under main landmarks directory
# (e.g., /hydra/S4/Landmarks3)
if [ ! -x "./checkRootDirectory.sh" ] || ! ./checkRootDirectory.sh; then
	echo >&2 "$0 needs to be executed under main landmarks directory (e.g., /hydra/S4/Landmarks3/)"
	exit
fi

INDEX_FILE=index_main_hydra.txt

if [ $# -ne 2 ]
then
    echo "Usage: $0 <landmark_name> <img_set_name>"
    exit
fi

LID="$1"
DIR="data/$LID"
IMAGE_DIR=$DIR/images
IMG_SET_NAME="$2"

# Get the list of images for this landmark
echo "Preparing list file..."
awk "\$2 == $LID { print \$3 }" $INDEX_FILE > $DIR/list_abs_hydra.txt
awk "{ print \"if [ -e\", \$0, \"]; then ln -s\", \$0, \"$IMAGE_DIR; fi\" }" $DIR/list_abs_hydra.txt > ln_$LID.txt

echo "Linking images..."
sh ln_$LID.txt
rm ln_$LID.txt
