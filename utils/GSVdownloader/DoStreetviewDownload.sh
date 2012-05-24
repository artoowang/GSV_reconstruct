#!/bin/bash

if [ $# -ne 2 ] 
then
    echo "Usage: DoStreetviewDownload.sh <landmark_id> <component_id>"
    exit
fi

LID=$(../../parseLID.sh "$1")		# Landmark ID
CID=$2
ID="$LID.$CID"

echo "ID: $ID"

# Directory for MATLAB scripts (make sure the execute permission is given for each level of directory)
SCRIPTS_DIR=/hydra/S4/Landmarks3/utils/GSVdownloader

# Run MATLAB scripts
cd $SCRIPTS_DIR
matlab -nodisplay -r "streetview_download('$LID', '$CID'); exit;"
