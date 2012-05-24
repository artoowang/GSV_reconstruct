#!/bin/bash

if [ $# -ne 2 ] 
then
    echo "Usage: $0 <landmark_id> <component_id>"
    exit
fi

NEATO=/hydra/S2/snavely/local/bin/neato
BUNDLE_TO_GRAPH=/hydra/S2/snavely/code/Bundler-lite/src/Bundle2Graph

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

# Make the graph
"$BUNDLE_TO_GRAPH" "geo/bundle.$CID.out" 10 > "geo/graph.$CID.dot"
"$NEATO" "geo/graph.$CID.dot" > "geo/graph.$CID.out"

# HTML output dir
OUTPUT_DIR="$ABS_ROOT/webroot/$LID/$CID"

# Copy the graph output to HTML dir
/bin/cp -f "geo/graph.$CID.out" "$OUTPUT_DIR/graph.out"

# Note: list.txt and thumbnail images should be already generated by DoVisualization.sh

cd ../..

# Modify the HTML template and move it to HTML dir
ESCAPED_URL=$(/bin/echo "$URL" | sed 's/\//\\\//g')
sed -e "s/%graphURL%/$ESCAPED_URL\/graph.out/" -e "s/%listURL%/$ESCAPED_URL\/list.txt/" -e "s/%imageURL%/$ESCAPED_URL/" html/graphview.html.tmpl > "$OUTPUT_DIR/graphview.html"
