#!/bin/bash
# Extract boundary frames from rendered legs (run with bash, never zsh — arrays/indexing).
# first_<n>.png = frame 0 (checking the start was obeyed)
# last_<n>.png  = final frame (handoff conditioning for the NEXT leg)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
NAMES="harvest atelier boutique finale"
for n in $NAMES; do
  [ -f "$WORK/dive_$n.mp4" ] || continue
  ffmpeg -v error -y -ss 0 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/first_$n.png"
  ffmpeg -v error -y -sseof -0.15 -i "$WORK/dive_$n.mp4" -frames:v 1 -q:v 2 "$WORK/last_$n.png"
  echo "frames   $n -> first_$n.png + last_$n.png"
done
