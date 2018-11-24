#!/bin/bash

USAGE="$0 <infile> <outfile>

Options:
  -s SHAKINESS, --shakiness=SHAKINESS  Shakiness [1-10] (default 5)
  -t STEPSIZE, --stepsize=STEPSIZE     Step size [0-100] (default 6)
  -a ACCURACY, --accuracy=ACCURACY     Accuracy [1-15] (default 5)
  -p, --process                        Skip detect, only run transform                                   
  -z ZOOM, --zoom=ZOOM                 Percent to zoom in [-500-500] (default 0)
  -o OPTZOOM, --optzoom=OPTZOOM        Automatically determine optimal zoom. 1 - static zoom, 2 - adaptive zoom (default 1)
  -m SMOOTHING, --smoothing=SMOOTHING  Number of frames for lowpass filtering (2N + 1 frames) [0-100] (default 15)
  --vectors=VECTORS                    Intermediate vectors file
"

main() {
  source parseargs.sh
  parseargs "$@"
  local transform_vectors="${VECTORS-${INFILE}.trf}"
  if [ -z "$PROCESS" ]; then
    local cmd="ffmpeg -i $INFILE -vf vidstabdetect=stepsize=${STEPSIZE-6}:shakiness=${SHAKINESS-5}:accuracy=${ACCURACY-5}:result=$transform_vectors -f null -"
    echo "$cmd"
    time $cmd
  fi
  local cmd="ffmpeg -i $INFILE -vf vidstabtransform=input=${transform_vectors}:zoom=${ZOOM-0}:optzoom=${OPTZOOM-1}:smoothing=${SMOOTHING-15},unsharp=5:5:0.8:3:3:0.4 -vcodec libx264 -preset slow -tune film -crf 18 -acodec copy $OUTFILE"
  echo "$cmd"
  time $cmd
}

main "$@"
