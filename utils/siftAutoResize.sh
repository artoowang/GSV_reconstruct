#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Usage: siftAutoResize.sh <input_image_name>"
	exit
fi

SIFT=/hydra/S2/snavely/bin/sift

file=$1
name=`echo $file | sed 's/^\(\S*\)\.\S*$/\1/'`
echo "Process $file"
# Seems that the maximum size Lowe's sift can handle is width(height)+kernel size < 8000
# Kernel size seems to be the same as the width(height), so the maximum possible image size would be 3999
# Use 3900
# Method 1: identify (slow)
w=`identify -format "%w" $file`
h=`identify -format "%h" $file`
# Method 2: jhead
#res=`jhead $file | grep Resolution`
#w=`echo $res | sed 's/Resolution\s*:\s*\([0-9]*\)\s*x\s*[0-9]*/\1/'`
#h=`echo $res | sed 's/Resolution\s*:\s*[0-9]*\s*x\s*\([0-9]*\)/\1/'`
# 10/12/11 Note: previously I used 3900x3900, but it seems that this is still too large when system is low on memory
if [ $w -ge 3000 -o $h -ge 3000 ]; then
	echo "Image $file is too large (${w}x${h}), resize it below 3000x3000"
	mogrify -resize 3000x3000 $file
fi
convert $file $name.pgm
$SIFT <$name.pgm >$name.key
gzip -f $name.key
rm -f $name.pgm

