#!/usr/bin/env bash
# sample-frames.sh — find candidate moments in ONE time window and write frames
# a vision model can actually read.
#
# Usage: scripts/sample-frames.sh <video> <out-dir> [start-s] [end-s] [interval-s]
#
# Why this script exists: the model cannot watch video. It reads stills. So every
# still has to carry its own absolute timestamp, or a coaching note cannot cite a
# minute. Frames are named by their real time in the match, not by frame number.
#
# Writes into <out-dir>:
#   frames/t<SECONDS>s-<MM-SS>.jpg   one still per interval, named by match time
#   sheets/sheet-NN.jpg              contact sheets covering the WHOLE window
#   scene.tsv                        scene-cut timestamps with scores
#   audio.tsv                        per-second audio peak levels (if audio)
#   candidates.tsv                   merged, deduped, sorted candidate list
#
# candidates.tsv is the file the workflow reads. Columns: start_s  end_s  mmss  source
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

VIDEO="${1:-}"
OUT="${2:-}"
START="${3:-0}"
END="${4:-}"
INTERVAL="${5:-2}"

if [[ -z "$VIDEO" || -z "$OUT" ]]; then
  echo "usage: scripts/sample-frames.sh <video> <out-dir> [start-s] [end-s] [interval-s]" >&2
  exit 1
fi

cp_need_ffmpeg
cp_need_file "$VIDEO"

TOTAL="$(cp_duration "$VIDEO")"
[[ -z "$END" ]] && END="$TOTAL"

WINDOW="$(cp_calc "$END - $START")"
case "$WINDOW" in
  -*|0.000) cp_die "empty window: start=$START end=$END" ;;
esac

mkdir -p "$OUT/frames" "$OUT/sheets"

# ---------------------------------------------------------------------------
# Stills, named by absolute match time.
# ---------------------------------------------------------------------------
# -ss before -i is the fast seek. Output PTS restarts at 0, so we add START back
# when naming. That is the whole trick that keeps timestamps honest.
rm -f "$OUT"/frames/*.jpg 2>/dev/null || true

ffmpeg -hide_banner -loglevel error \
  -ss "$START" -i "$VIDEO" -t "$WINDOW" \
  -vf "fps=1/${INTERVAL},scale=960:-2" \
  -q:v 4 -frame_pts 1 "$OUT/frames/raw-%06d.jpg" 2>/dev/null || true

# raw-NNNNNN.jpg is indexed in units of the output frame rate, i.e. one per
# INTERVAL seconds. Rename to absolute match time.
n=0
for f in "$OUT"/frames/raw-*.jpg; do
  [[ -e "$f" ]] || break
  idx="$(basename "$f" .jpg)"; idx="${idx#raw-}"
  idx="$(echo "$idx" | sed 's/^0*//')"; [[ -z "$idx" ]] && idx=0
  abs="$(cp_calc "$START + $idx * $INTERVAL")"
  absi="${abs%.*}"
  mv "$f" "$OUT/frames/t${absi}s-$(cp_mmss "$abs" | tr ':' '-').jpg"
  n=$((n+1))
done

# ---------------------------------------------------------------------------
# Contact sheets covering the WHOLE window.
# ---------------------------------------------------------------------------
# A single fixed 10x10 tile silently truncates: an 18-minute part at 1 fps needs
# 1080 tiles, so one sheet showed the first 100 seconds and dropped the rest.
# Sample at the same INTERVAL and let ffmpeg emit as many sheets as it needs.
ffmpeg -hide_banner -loglevel error \
  -ss "$START" -i "$VIDEO" -t "$WINDOW" \
  -vf "fps=1/${INTERVAL},scale=320:-2,tile=6x5" \
  -q:v 4 "$OUT/sheets/sheet-%02d.jpg" 2>/dev/null || true

SHEETS="$(find "$OUT/sheets" -name 'sheet-*.jpg' 2>/dev/null | wc -l | tr -d ' ')"

# Each sheet holds 30 tiles at INTERVAL spacing. Record the mapping so a human
# (and the model) can turn "tile 14 of sheet 2" back into a match minute.
{
  echo "# sheet grid 6x5 = 30 tiles per sheet, ${INTERVAL}s per tile"
  echo "# tiles fill left to right, top to bottom"
  echo "# sheet  first_tile_s  last_tile_s  first_mmss  last_mmss"
  i=1
  while [[ "$i" -le "${SHEETS:-0}" ]]; do
    first="$(cp_calc "$START + ($i - 1) * 30 * $INTERVAL")"
    last="$(cp_calc "$first + 29 * $INTERVAL")"
    printf "%02d\t%s\t%s\t%s\t%s\n" "$i" "${first%.*}" "${last%.*}" "$(cp_mmss "$first")" "$(cp_mmss "$last")"
    i=$((i+1))
  done
} > "$OUT/sheets/MAP.tsv"

# ---------------------------------------------------------------------------
# Detector A — scene cuts, WITH timestamps.
# ---------------------------------------------------------------------------
# showinfo writes to stderr at loglevel info. The old recipe ran at loglevel
# error and threw every timestamp away, so scene detection produced numbered
# jpgs and no way to know when they happened. metadata=print writes to a file
# and survives any loglevel.
ffmpeg -hide_banner -loglevel error \
  -ss "$START" -i "$VIDEO" -t "$WINDOW" \
  -vf "select='gt(scene,0.3)',metadata=print:file=$OUT/scene.raw" \
  -an -f null - 2>/dev/null || true

{
  printf "ts_s\tmmss\tscene_score\n"
  if [[ -f "$OUT/scene.raw" ]]; then
    awk -v off="$START" '
      /pts_time:/ { t=$0; sub(/.*pts_time:/,"",t); sub(/[^0-9.].*$/,"",t); pend=t+off }
      /scene_score=/ { v=$0; sub(/.*=/,"",v);
        if (pend!="") { printf "%.2f\t%d:%02d\t%.3f\n", pend, int(pend/60), pend-int(pend/60)*60, v; pend="" } }
    ' "$OUT/scene.raw"
  fi
} > "$OUT/scene.tsv"
rm -f "$OUT/scene.raw"

SCENES="$(( $(wc -l < "$OUT/scene.tsv") - 1 ))"

# ---------------------------------------------------------------------------
# Detector B — audio peaks. Whistles and shouts are cheap goal/foul signals.
# ---------------------------------------------------------------------------
HAVE_AUDIO="no"
if cp_has_audio "$VIDEO"; then
  HAVE_AUDIO="yes"
  ffmpeg -hide_banner -loglevel error \
    -ss "$START" -i "$VIDEO" -t "$WINDOW" \
    -vn -af "asetnsamples=n=48000,astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.Peak_level:file=$OUT/audio.raw" \
    -f null - 2>/dev/null || true

  {
    printf "ts_s\tmmss\tpeak_db\n"
    if [[ -f "$OUT/audio.raw" ]]; then
      awk -v off="$START" '
        /pts_time:/ { t=$0; sub(/.*pts_time:/,"",t); sub(/[^0-9.].*$/,"",t); cur=t+off }
        /Peak_level=/ { v=$0; sub(/.*=/,"",v);
          if (cur!="" && v+0 != 0) { printf "%.2f\t%d:%02d\t%.2f\n", cur, int(cur/60), cur-int(cur/60)*60, v; cur="" } }
      ' "$OUT/audio.raw"
    fi
  } > "$OUT/audio.tsv"
  rm -f "$OUT/audio.raw"

  # Loud outliers only: mean + 6 dB. Amateur tape is noisy, so this is a hint,
  # not a fact. The review stage decides.
  awk -F'\t' 'NR>1 && $3 != "" { s+=$3; n++ } END { if (n>0) printf "%.2f\n", (s/n)+6 }' \
    "$OUT/audio.tsv" > "$OUT/.audio_thresh" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Merge into candidates.tsv. Dedup inside 8 seconds, as the workflow specifies.
# ---------------------------------------------------------------------------
{
  awk -F'\t' 'NR>1 && $1 != "" { printf "%.2f\tscene\n", $1 }' "$OUT/scene.tsv"
  if [[ "$HAVE_AUDIO" == "yes" && -s "$OUT/.audio_thresh" ]]; then
    THRESH="$(cat "$OUT/.audio_thresh")"
    awk -F'\t' -v th="$THRESH" 'NR>1 && $3 != "" && $3+0 > th+0 { printf "%.2f\taudio\n", $1 }' "$OUT/audio.tsv"
  fi
} | sort -n -k1,1 | awk -F'\t' '
  BEGIN { printf "start_s\tend_s\tmmss\tsource\n"; last=-999 }
  {
    ts=$1+0
    if (ts - last < 8) { src[last] = src[last] "+" $2; next }
    last=ts; order[++c]=ts; src[ts]=$2
  }
  END {
    for (i=1;i<=c;i++) {
      t=order[i]; s=(t-3<0?0:t-3); e=t+6
      printf "%.2f\t%.2f\t%d:%02d\t%s\n", s, e, int(t/60), t-int(t/60)*60, src[t]
    }
  }
' > "$OUT/candidates.tsv"
rm -f "$OUT/.audio_thresh"

CANDS="$(( $(wc -l < "$OUT/candidates.tsv") - 1 ))"

cat <<EOF
window_s: $START to ${END%.*}
frames: $n in $OUT/frames (named by match time)
sheets: ${SHEETS:-0} in $OUT/sheets (map: $OUT/sheets/MAP.tsv)
scene_cuts: $SCENES ($OUT/scene.tsv)
audio: $HAVE_AUDIO $( [[ "$HAVE_AUDIO" == "yes" ]] && echo "($OUT/audio.tsv)" )
candidates: $CANDS ($OUT/candidates.tsv)

Next: read candidates.tsv, then review each window. Detectors find noise as well
as goals. Prefer recall here. The review stage cuts.
Detectors cannot see a turnover. You still have to look at the frames.
EOF
