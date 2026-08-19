#!/bin/bash
# Validate the 4 dropped scene stills: present, opens, >=1200px wide, ~16:9.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
NAMES="harvest atelier boutique finale"
fail=0
for n in $NAMES; do
  f=""
  for ext in png jpg jpeg webp; do
    [ -f "$WORK/still_$n.$ext" ] && f="$WORK/still_$n.$ext" && break
  done
  if [ -z "$f" ]; then echo "MISSING  still_$n.(png|jpg) — not dropped yet"; fail=1; continue; fi
  read w h <<EOF
$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f" | tr ',' ' ')
EOF
  if [ -z "${w:-}" ] || [ -z "${h:-}" ]; then echo "FAIL     $f — unreadable"; fail=1; continue; fi
  ok=$(awk -v w="$w" -v h="$h" 'BEGIN{ r=w/h; print (w>=1200 && r>1.68 && r<1.87) ? "yes" : "no" }')
  if [ "$ok" = "yes" ]; then
    echo "OK       still_$n  ${w}x${h}"
  else
    echo "FAIL     still_$n  ${w}x${h} — need 16:9-ish and >=1200px wide"; fail=1
  fi
done
[ "$fail" = 0 ] && echo "All stills valid." || exit 1
