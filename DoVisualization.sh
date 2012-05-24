#!/bin/bash

if [ $# -ne 2 ] 
then
    echo "Usage: $0 <landmark_id> <component_id>"
    exit
fi

# This script assumes it executed under main landmarks directory
# (e.g., /hydra/S4/Landmarks3)
if [ ! -x "./checkRootDirectory.sh" ] || ! ./checkRootDirectory.sh; then
	echo >&2 "$0 needs to be executed under main landmarks directory (e.g., /hydra/S4/Landmarks3/)"
	exit
fi

ABS_ROOT=$(pwd)
LID=$(./parseLID.sh "$1")		# Landmark ID
CID=$2
ID="$LID.$CID"
DIR="data/$LID"
URL="$(cat base_url.txt)/$LID/$CID"

echo "ID: $ID"

# Change to dataset directory, and get absolute directory
cd $DIR
ABS_COMP=$(pwd)

# Directory for MATLAB scripts (make sure the execute permission is given for each level of directory)
SCRIPTS_DIR=/home/cpwang/symlinks/photowhen/groundTruths/src

# Output web directory
OUTPUT_DIR="$ABS_ROOT/webroot/$LID/$CID"

# Clean output dir
# Warning: make sure $ID is not empty
if [ -z $ID ]; then
	echo "ID is empty. Abort"
	exit
fi
echo "Removing output directory $OUTPUT_DIR"
rm -rf $OUTPUT_DIR

# Run MATLAB scripts
cd $SCRIPTS_DIR
matlab -nodisplay -r "makeHTMLPhotoList('$OUTPUT_DIR', '$ID', '$ABS_COMP/geo/list.$CID.txt', '$ABS_COMP/geo/bundle.$CID.out', '$ABS_COMP', 'm', [], [], '$URL'); exit;" 2>&1 | tee $ABS_COMP/geo/visualization.$CID.log

# Generate graphview
cd "$ABS_ROOT"	# Go back to main landmarks directory
./DoGraphVisualization.sh $LID $CID

