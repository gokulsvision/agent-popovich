#!/usr/bin/env bash
# cut-moment.sh — short clip plus stills around one timestamp.
#
# Usage: scripts/cut-moment.sh <video> <out-dir> <timestamp-s> [before] [after]
#
# Windows the workflow uses:
#   goals      5 before,  8 after
#   turnovers  3 before,  6 after
#   other      3 before,  5 after   (the default)
#
# Come-or-stay cannot be judged from one thumbnail. This writes motion plus a
# strip of stills named by absolute match time, so a note can cite a real minute.
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

VIDEO="${1:-}"
OUT="${2:-}"
TS="${3:-}"
BEFORE="${4:-3}"
AFTER="${5:-5}"

if [[ -z "$VIDEO" || -z "$OUT" || -z "$TS" ]]; then
  echo "usage: scripts/cut-moment.sh <video> <out-dir> <timestamp-s> [before] [after]" >&2
  exit 1
fi

cp_need_ffmpeg
cp_need_file "$VIDEO"

mkdir -p "$OUT"

START="$(awk -v t="$TS" -v b="$BEFORE" 'BEGIN{ v=t-b; printf "%.3f\n", (v<0?0:v) }')"
DUR="$(cp_calc "$BEFORE + $AFTER")"
LABEL="$(cp_mmss "$TS" | tr ':' '-')"

CLIP="$OUT/clip-t${TS%.*}s-${LABEL}.mp4"

# Accurate seek: -ss AFTER -i. Slower but frame-exact, which matters when the
# whole judgement is where the keeper was two seconds before the shot.
ffmpeg -hide_banner -loglevel error \
  -i "$VIDEO" -ss "$START" -t "$DUR" \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
  -c:a aac -movflags +faststart \
  -y "$CLIP" 2>/dev/null

# One still per second across the window, named by absolute match time.
rm -f "$OUT"/raw-*.jpg 2>/dev/null || true
ffmpeg -hide_banner -loglevel error \
  -i "$VIDEO" -ss "$START" -t "$DUR" \
  -vf "fps=1,scale=960:-2" -q:v 3 \
  -y "$OUT/raw-%03d.jpg" 2>/dev/null

n=0
for f in "$OUT"/raw-*.jpg; do
  [[ -e "$f" ]] || break
  idx="$(basename "$f" .jpg)"; idx="${idx#raw-}"
  idx="$(echo "$idx" | sed 's/^0*//')"; [[ -z "$idx" ]] && idx=0
  # ffmpeg image2 numbering starts at 1, so subtract one to get the offset.
  abs="$(cp_calc "$START + ($idx - 1)")"
  absi="${abs%.*}"
  mv "$f" "$OUT/t${absi}s-$(cp_mmss "$abs" | tr ':' '-').jpg"
  n=$((n+1))
done

cat <<EOF
clip: $CLIP
moment_mmss: $(cp_mmss "$TS")
window: $(cp_mmss "$START") to $(cp_mmss "$(cp_calc "$START + $DUR")")
stills: $n in $OUT (named by match time)

Watch the clip for come-or-stay. Do not score it from a single still.
If it is unreadable, write unreadable. Do not guess.
EOF
