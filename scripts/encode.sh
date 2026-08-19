#!/bin/bash
# Final encode for smooth scroll-scrubbing (pipeline.md §5): native resolution,
# crf 20, GOP 8, light sharpen, no audio, faststart. Stills -> webp posters.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
ASSETS="$ROOT/assets"
mkdir -p "$ASSETS/vid"
NAMES="harvest atelier boutique finale"

enc() { ffmpeg -v error -y -i "$1" -an -vf "unsharp=5:5:0.8:5:5:0.0" \
  -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
  -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart "$2" \
  && echo "enc  $2  $(du -h "$2" | cut -f1)"; }

for n in $NAMES; do
  if [ -f "$WORK/dive_$n.mp4" ]; then enc "$WORK/dive_$n.mp4" "$ASSETS/vid/$n.mp4"
  else echo "skip  dive_$n.mp4 (missing)"; fi
done

python3 "$ROOT/scripts/to_webp.py"
echo "Done. Preview: cd '$ROOT' && python3 -m http.server 8000"
