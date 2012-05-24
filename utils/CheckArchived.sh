#!/bin/bash
# Check the status of archived models

MODEL_STATUS_FILE=/hydra/S4/Landmarks3/MODEL_STATUS.txt

awk 'NR > 1 && NF == 5 && $5 == 1 { printf("echo Checking archived model %d; ls data/%04d/images/*.jpg\n", $1, $1) }' $MODEL_STATUS_FILE > .tmp/archive-script.txt

sh .tmp/archive-script.txt
