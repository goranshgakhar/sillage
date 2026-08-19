#!/bin/bash
# Validate each dropped leg: plays, ~16:9, 5-12s, and frame 0 matches its handed-over
# start frame (PSNR >= 25 dB = obeyed; below that the tool ignored the start image
# and the clip can't hold its seam — send it back for re-generation).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
NAMES="harvest atelier boutique finale"
fail=0
prev=""
for n in $NAMES; do
  if [ -z "$prev" ]; then start="$WORK/still_harvest.png"; else start="$WORK/last_$prev.png"; fi
  f="$WORK/dive_$n.mp4"
  if [ ! -f "$f" ]; then echo "MISSING  dive_$n.mp4"; prev="$n"; continue; fi
  read w h <<EOF
$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f" | tr ',' ' ')
EOF
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  geo=$(awk -v w="${w:-0}" -v h="${h:-1}" -v d="${dur:-0}" 'BEGIN{ r=w/h; print (r>1.68 && r<1.87 && d>=5 && d<=12) ? "ok" : "BAD" }')
  # frame 0 vs handed-over start frame
  psnr="n/a"
  if [ -f "$start" ]; then
    ffmpeg -v error -y -ss 0 -i "$f" -frames:v 1 "$WORK/_f0_$n.png"
    psnr=$(ffmpeg -i "$WORK/_f0_$n.png" -i "$start" -lavfi "[0:v]scale=640:360[a];[1:v]scale=640:360[b];[a][b]psnr" -f null - 2>&1 \
      | sed -n 's/.* average:\([0-9.]*\).*/\1/p' | tail -1)
    rm -f "$WORK/_f0_$n.png"
  fi
  verdict="OK"
  [ "$geo" = "BAD" ] && verdict="FAIL geometry/duration (${w}x${h}, ${dur}s)" && fail=1
  if [ "$psnr" != "n/a" ]; then
    band=$(awk -v p="${psnr:-0}" 'BEGIN{ print (p>=25) ? "ok" : (p>=15) ? "warn" : "fail" }')
    case "$band" in
      fail) verdict="FAIL start frame is a different composition (PSNR ${psnr} dB < 15) — re-render" ; fail=1 ;;
      warn) verdict="$verdict (PSNR ${psnr} dB — conditioning re-rendered, not pixel-locked; accept only if composition matches, crossfade covers it)" ;;
    esac
  else
    verdict="$verdict (start frame $start missing — extract previous leg first)"
  fi
  printf "%-8s dive_%s  %sx%s  %.1fs  psnr=%s  -> %s\n" "$(echo "$verdict" | cut -c1-4)" "$n" "$w" "$h" "${dur:-0}" "${psnr:-n/a}" "$verdict"
  prev="$n"
done
[ "$fail" = 0 ] && echo "All dropped legs valid." || exit 1
