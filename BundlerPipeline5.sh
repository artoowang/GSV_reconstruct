#!/bin/bash
# BundlerPipeline4.sh -- run version 4 of the Bundler pipeline

date
TIME=`date "+%b%d_%H%M"`

BIN_PATH=/hydra/S2/snavely/bin
VOCABTREE_PATH=/hydra/S2/snavely/code/VocabTree2
GSV_RECON_PATH=/home/cpwang/symlinks/GSV_reconstruct

EXTRACT_FOCAL=$BIN_PATH/extract_focal.pl

#NUM_NODES=30
NUM_NODES=18
#NUM_NNS=80
NUM_NNS=40

SIFT=sift

# VOCAB_BUILD_DB=$VOCABTREE_PATH/bin/VocabBuildDB.64
VOCAB_BUILD_DB=$VOCABTREE_PATH/VocabBuildDB/VocabBuildDB
VOCAB_COMBINE=$VOCABTREE_PATH/src/VocabCombine
VOCAB_FILE=$VOCABTREE_PATH/trees/tree.5.10.out
DIVIDE_MATCHING=$BIN_PATH/bundler_gen5/divideMatchingProblem.py
DIVIDE_DATABASE=$BIN_PATH/bundler_gen5/divideDatabaseProblem.py
PROCESS_PREMATCHING=$BIN_PATH/bundler_gen5/processPreMatches.sh
TO_SIFT=$BIN_PATH/bundler_gen5/ToSift.sh
TO_SIFT_LIST=$BIN_PATH/bundler_gen5/ToSiftList.sh
CONVERT_SAMEER=$BIN_PATH/bundler_gen5/ConvertAllKeyfilesToSameer.sh
GENERATE_BUILDPAIR_SCRIPT=$BIN_PATH/bundler_gen5/generateBuildPairScript.py
GENERATE_MATCH_INDEX2=$BIN_PATH/bundler_gen5/genMatchIndex2.sh
GENERATE_BUILDPAIR_INDEX2=$BIN_PATH/bundler_gen5/genBuildPairIndex2.sh
# CONVERT_BUILDPAIR_TO_MATCH_FILE=$BIN_PATH/bundler_gen5/convertBuildPairToMatchFile.py
GENERATE_COMPONENT_FILES=$BIN_PATH/bundler_gen5/GenerateComponentFiles.py
GENERATE_SKELETAL_SCRIPT2=$BIN_PATH/bundler_gen5/GenerateSkeletalScript2.sh
GENERATE_BUNDLER_SCRIPT=$BIN_PATH/bundler_gen5/GenerateBundlerScript.sh
BUNDLER=$BIN_PATH/bundler_gen5/bundler64
GPS_PREMATCHING=$GSV_RECON_PATH/prematchingUsingGPS.py

PCHEF_EXEC=$BIN_PATH/PancakeChef-exec3.sh

IMAGE_DIR="."
IMAGE_OUTPUT_DIR="images"
IMAGE_ORIG_DIR="images_orig"

# MAX_RESOLUTION="1600x1600"
#MAX_RESOLUTION="2000x2000"
MAX_RESOLUTION="2400x2400"
#MAX_RESOLUTION="3200x3200"
#MAX_RESOLUTION="3400x3400"

if [ $# -ge 1 ]
then
    echo "Using directory '$1'"
    IMAGE_DIR=$1
fi

if [ $# -eq 2 ]
then
    echo "Using resolution '$2'"
    MAX_RESOLUTION=$2
fi

if [ $# -eq 3 ]
then
    echo "Using num_nns '$3'"
    NUM_NNS=$3
fi

if [ "$SKIP_SIFT" == "" ]
then
  mkdir -p $IMAGE_OUTPUT_DIR
  mkdir -p $IMAGE_ORIG_DIR

  # for d in `ls -1 $IMAGE_DIR | egrep ".JPG$"` 
  # Resize images

  if [ "$IMAGE_LIST" == "" ]
  then
      rm -rf resize.txt
      echo "[- Renaming and resizing images -]"
      for d in `find . -name "*.[Jj][Pp][Gg]" | grep -v ".unused" | sort`
      do 
        # Remove empty images
        if [ -s $IMAGE_DIR/$d ]
        then
          name=`echo $d | sed 's/\.JPG/\.jpg/'`
          basename=`basename $name`
          # cp $IMAGE_DIR/$d $IMAGE_ORIG_DIR/$name
	  # rm $IMAGE_DIR/$d
          # echo "convert -resize $MAX_RESOLUTION\\\> $IMAGE_ORIG_DIR/$name $IMAGE_OUTPUT_DIR/$name" >> resize.txt
          echo "convert -resize $MAX_RESOLUTION\\> $IMAGE_DIR/$d $IMAGE_OUTPUT_DIR/$basename; jhead -autorot $IMAGE_OUTPUT_DIR/$basename" >> resize.txt
          # cp $IMAGE_ORIG_DIR/$name $IMAGE_OUTPUT_DIR/$name
        else
          echo "Removing empty image $d"
          rm $IMAGE_DIR/$d
        fi
    done

    # Distribute the resizing jobs
    $PCHEF_EXEC resize.txt $NUM_NODES
  fi

# ...
# ...
# ...

  if [ "$IMAGE_LIST" == "" ]
  then
    # Create the list of images
    # find . -name "*.jpg" | grep -v ".unused" | sort > list_tmp.txt
    find $IMAGE_OUTPUT_DIR -mindepth 1 | egrep ".jpg$" | sort > list_tmp.txt
    # ls -1 $IMAGE_OUTPUT_DIR | sort > list_tmp.txt
  else
    awk '{print $1}' $IMAGE_LIST > list_tmp.txt
  fi

  # Run the ToSift script to create jobs
  echo "[- Extracting keypoints -]"
  rm -f sift.txt

  $TO_SIFT_LIST list_tmp.txt > sift.txt 
  $PCHEF_EXEC sift.txt $NUM_NODES
  date
else
  if [ "$IMAGE_LIST" == "" ]
  then
    # Create the list of images
    # find . -name "*.jpg" | grep -v ".unused" | sort > list_tmp.txt
    find $IMAGE_OUTPUT_DIR -mindepth 1 | egrep ".jpg$" | sort > list_tmp.txt
    # ls -1 $IMAGE_OUTPUT_DIR | sort > list_tmp.txt
  else
    awk '{print $1}' $IMAGE_LIST > list_tmp.txt
  fi
fi # $SKIP_SIFT

sed 's/\.jpg$/\.key/' list_tmp.txt > list_keys.txt

if [ "$SKIP_MATCHING" == "" ]
then
  echo "[- Matching keypoints -]"
  mkdir matches

  if [ "$SKIP_PREMATCHING" == "" ]
  then
	if [ "$DO_GPS_PREMATCHING" == "" ]
	then
      mkdir prematch_jobs
      mkdir prematch

      echo "  ==> Building image database..."
      # $VOCAB_BUILD_DB list_keys.txt $VOCAB_FILE db.out # 1 1.4 1 # 2500
      mkdir db_jobs
      mkdir db_work
      $DIVIDE_DATABASE list_keys.txt $VOCAB_FILE $NUM_NODES \
          db_script.txt db_jobs db_work

      # Execute the db jobs
      $PCHEF_EXEC db_script.txt $NUM_NODES

      # Combine dbs together
      $VOCAB_COMBINE db_work/db_*.out db.out

      # Clean up
      rm -rf db_work/db_*.out

      echo "  ==> Prematching..."
      $DIVIDE_MATCHING list_keys.txt db.out $NUM_NNS $NUM_NODES \
          prematch_script.txt prematch_jobs prematch

      # Execute the prematch jobs
      $PCHEF_EXEC prematch_script.txt $NUM_NODES
    else
      mkdir prematch

      echo "  ==> Prematching..."
	  $GPS_PREMATCHING $IMAGE_LIST $NUM_NNS $NUM_NODES prematch
	fi
  fi

  # Now combine matches together
  mkdir match_scripts
  MATCH_TMP_DIR=/tmp/`whoami`/`pwd`/`date | sed 's/ /_/g'`
  $PROCESS_PREMATCHING list_keys.txt prematch matches match_scripts match_script.txt $MATCH_TMP_DIR

  # Launch match jobs
  echo "  ==> Performing detailed matching..."
  $PCHEF_EXEC match_script.txt $NUM_NODES $MATCH_TMP_DIR

  # Generate the match index
  $GENERATE_MATCH_INDEX2 matches match-index.txt
fi

if [ "$IMAGE_LIST" == "" ]
then
  # While that's happening, extract focal length information
  $EXTRACT_FOCAL list_tmp.txt
  cp prepare/list.txt .
  IMAGE_LIST=list.txt
fi

# ...
# ...
# ...
# ...
# ...

if [ "$SKIP_SAMEER" == "" ]
then
  $CONVERT_SAMEER $IMAGE_LIST $FISHEYE_FILE > convert_sameer.txt
  $PCHEF_EXEC convert_sameer.txt 5
  date
fi

awk '{print $1}' $IMAGE_LIST | sed 's/jpg/ks/' > list_ks.txt


if [ "$SKIP_BUILDPAIR" == "" ]
then
  # Convert to Sameer's format

# ...
# ...
# ...
# ...
# ...

  echo "[- Refining matches -]"

  # Generate the BuildPair script
  mkdir buildpair_files
  mkdir matches_buildpair
  BUILDPAIR_TMP_DIR=/tmp/`whoami`/`pwd`/`date | sed 's/ /_/g'`
  $GENERATE_BUILDPAIR_SCRIPT list_ks.txt matches buildpair-script.txt buildpair_files matches_buildpair $BUILDPAIR_TMP_DIR

  # Run the BuildPair script
  $PCHEF_EXEC buildpair-script.txt $NUM_NODES $BUILDPAIR_TMP_DIR
fi

if [ "$SKIP_TRACKS" == "" ]
then
  rm -f constraints.txt
  rm -f track-pairs.txt

  # Next, generate tracks and output new matches
  mkdir matches_tracks
  rm -f options.tracks.txt
  echo "--match_index_dir matches_buildpair" >> options.tracks.txt
  echo "--output_dir matches_tracks" >> options.tracks.txt
  echo "--skip_fmatrix" >> options.tracks.txt
  echo "--skip_homographies" >> options.tracks.txt
  echo "--generate_tracks matches_tracks" >> options.tracks.txt
  echo "--write_match_indices" >> options.tracks.txt
#  echo "--min_feature_matches 32" >> options.tracks.txt
#  echo "--min_feature_matches 18" >> options.tracks.txt
  echo "--min_feature_matches 14" >> options.tracks.txt
#  echo "--min_feature_matches 32" >> options.tracks.txt
  echo "--max_track_views 400" >> options.tracks.txt

  echo "[- Generating tracks -]"
  $BUNDLER $IMAGE_LIST --options_file options.tracks.txt > tracks.log

  # Generate the match-tracks-index.txt file
  $GENERATE_MATCH_INDEX2 matches_tracks match-tracks-index.txt
fi

if [ "$SKIP_BUILDPAIR_TRACKS" == "" ]
then
    # Run one more round of buildpair
    mkdir buildpair_tracks_files
    BUILDPAIR_TRACKS_TMP_DIR=/tmp/`whoami`/`pwd`/`date | sed 's/ /_/g'`
    $GENERATE_BUILDPAIR_SCRIPT list_ks.txt matches_tracks buildpair-tracks-script.txt buildpair_tracks_files none $BUILDPAIR_TRACKS_TMP_DIR

    # Run the BuildPair script
    $PCHEF_EXEC buildpair-tracks-script.txt $NUM_NODES $BUILDPAIR_TRACKS_TMP_DIR

    # $GENERATE_COMPONENT_FILES list_keys.txt buildpair-index.txt skeletal_input/components.txt
fi

# Coalesce BuildPair outputs
$GENERATE_MATCH_INDEX2 matches_buildpair buildpair-index.txt
$GENERATE_BUILDPAIR_INDEX2 buildpair_tracks_files buildpair-tracks-index.txt
#ls -1 buildpair_tracks_files > buildpair_tracks_files.txt
mkdir skeletal_input
$GENERATE_COMPONENT_FILES list_keys.txt buildpair-tracks-index.txt skeletal_input/components.txt


# Run skeletal sets
echo "[- Running skeletal sets -]"
mkdir skeletal_output
# $GENERATE_SKELETAL_SCRIPT $IMAGE_LIST skeletal_input/components.txt buildpair_tracks_files buildpair-tracks-index.txt skeletal_output 9 > skeletal-script.txt
$GENERATE_SKELETAL_SCRIPT2 $IMAGE_LIST skeletal_input/components.txt buildpair_tracks_files skeletal_output 9 25 $FISHEYE_FILE > skeletal-script.txt

# Execute the skeletal script
$PCHEF_EXEC skeletal-script.txt $NUM_NODES

# ...
# ...
# ...
# ...

# Run the bundler!
mkdir results
$GENERATE_BUNDLER_SCRIPT $IMAGE_LIST skeletal_output results 9 > bundler-script.txt

echo "[- Running bundler -]"

$PCHEF_EXEC bundler-script.txt $NUM_NODES

# mkdir bundle

# rm -f options.txt

# echo "--match_dir matches_buildpair" >> options.txt
# echo "--output bundle.out" >> options.txt
# echo "--output_all bundle_" >> options.txt
# echo "--output_dir bundle" >> options.txt
# echo "--skip_fmatrix" >> options.txt
# echo "--init_focal_length 3995.486809" >> options.txt
# echo "--variable_focal_length" >> options.txt
# echo "--projection_estimation_threshold 4.0" >> options.txt
# echo "--run_bundle" >> options.txt
# echo "--min_camera_distance_ratio 0.0" >> options.txt
# echo "--ray_angle_threshold 2.0" >> options.txt
# echo "--use_focal_estimate" >> options.txt
# echo "--trust_focal_estimate" >> options.txt
# echo "--constrain_focal" >> options.txt
# echo "--constrain_focal_weight 0.0001" >> options.txt
# echo "--estimate_distortion" >> options.txt
# echo "--min_proj_error_threshold 4.0" >> options.txt
# echo "--max_proj_error_threshold 8.0" >> options.txt

# # Uncomment these two lines if using fisheye images
# # FISHEYE_FILE=Sigma8mm_TS.txt
# # echo "--fisheye $FISHEYE_FILE" >> options.txt

# rm -f constraints.txt
# rm -f track-pairs.txt

# # Create a bsub job
# echo "$BUNDLER list.txt --options_file options.txt > bundle/out" > bundle.txt
# bsub-exec.sh bundle.txt BUNDLER-$TIME 

# # MATCH-$TIME
