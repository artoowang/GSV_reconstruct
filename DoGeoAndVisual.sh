#!/bin/bash

if [ $# -ne 2 ]; then
	echo >&2 "Usage: $0 <landmark_id> <component_id>"
	exit
fi

# This script assumes it executed under main landmarks directory
# (e.g., /hydra/S4/Landmarks3)
if [ ! -x "./checkRootDirectory.sh" ] || ! ./checkRootDirectory.sh; then
	echo >&2 "$0 needs to be executed under main landmarks directory (e.g., /hydra/S4/Landmarks3/)"
	exit
fi

./DoGeoregistration.sh $1 $2
./DoVisualization.sh $1 $2

