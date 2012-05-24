#!/bin/bash

BUNDLER64=/hydra/S2/snavely/code/Bundler-lite/bin/bundler64
BUNDLER_PIPELINE=/home/cpwang/symlinks/GSV_reconstruct/BundlerPipeline5.sh

function usage () {
	echo >&2 "Usage: $0 <landmark_name> <img_set_name>"
	exit
}

if [ $# -ne 2 ]; then usage; fi

# This script assumes it executed under main landmarks directory
# (e.g., /hydra/S4/Landmarks3)
ABS_ROOT=$(pwd)
if [ ! -x "./checkRootDirectory.sh" ] || ! ./checkRootDirectory.sh; then
	echo >&2 "$0 needs to be executed under main landmarks directory (e.g., /hydra/S4/Landmarks3/)"
	exit
fi

LID="$1"
LID_STR="$LID"
DIR="data/$LID_STR"
DIR_LARGE="data_large/$LID_STR"
IMG_SET_NAME="$2"

echo "Landmark name: $LID_STR"

# Clean previous results
if [ -z $LID_STR -o $DIR = "data" -o $DIR = "data/" -o $DIR_LARGE = "data_large" -o $DIR_LARGE = "data_large/" ]	# Make sure $LID_STR is not empty; otherwise the whole data directory will be removed
then
	echo "Invalid LID: $LID_STR"
	exit
fi
echo "Cleaning previous results..."
rm -rf "$DIR"
rm -rf "$DIR_LARGE"

# Create dataset directories (main and large file directory)
mkdir -p "$DIR"
mkdir -p "$DIR_LARGE"
mkdir -p "$DIR_LARGE/keys_new"

# Create symlinks
ln -s "../../$DIR_LARGE" "$DIR/data_large"
ln -s "data_large/keys_new" "$DIR/"
ln -s "../../image_sets/$IMG_SET_NAME/images" "$DIR/"
ln -s "../../image_sets/$IMG_SET_NAME/list.txt" "$DIR/"
ln -s "../../image_sets/$IMG_SET_NAME/geotags_uniq.txt" "$DIR/"

touch $DIR/.processing	# Let DoUpdateStatus.sh know this landmark is still being processed

# Change to dataset directory
cd $DIR

# list.txt and SIFT features are already extracted in each image set. We have too many images,
# so it's inefficient to rerun SIFT on all of them each time. This script will use existing results
# and only rerun BundlerPipeline5.sh

# Run bundler
echo "Running bundler..."
export IMAGE_LIST=list.txt
export SKIP_SIFT=1			# Skip SIFT
# Run my own BundlerPipeline5.sh
$BUNDLER_PIPELINE | tee bundler.log

# Reindex SIFT keys
echo "Reindexing SIFT keys..."
"$BUNDLER64" list.txt --write_all_keys --output_dir keys_new 2>&1 | tee reindex.log
echo "Compressing new keys..."
gzip keys_new/*.key

# Marshall the reconstructions
if [ -d "bundles_new" ]; then
	# bundles_new exists; remove it and re-do
	echo "Removing existing bundles_new ..."
	rm -rf bundles_new
fi

mkdir -p log

echo "Marshalling reconstructions..."
bundles=`ls results/bundle.*/bundle.out`
mkdir -p bundles_new
mkdir -p geo

for b in $bundles
do
    id=`echo $b | sed 's/.*results\/bundle\.//' | sed 's/\/bundle.out//'`
    echo $id

	"$BUNDLER64" list.txt --bundle $b --compress_list > log/compress.$id.log
    mv list.compressed.txt bundles_new/list.$id.txt
    mv bundle.compressed.out bundles_new/bundle.$id.out

	# ------------------------------------------------------------------
	#  Georegistration and Visualization
	# ------------------------------------------------------------------
	cd ../..
	./DoGeoAndVisual.sh $LID $id
	cd $DIR
done

rm -f .processing	# Done
