#!/bin/bash

utils/CheckModelStatus.sh /home/cpwang/symlinks/GSV_reconstruct >stats.txt 2>stats_error.txt
cp stats.txt webroot/

