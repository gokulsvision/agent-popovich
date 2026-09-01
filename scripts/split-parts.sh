#!/usr/bin/env bash
# split-parts.sh — compute five equal time parts after kickoff.
#
# Usage: scripts/split-parts.sh <video> [kickoff-s] [parts]
#
# This does NOT re-encode and does NOT write video files. Splitting a 90-minute
# match into five real mp4s would copy gigabytes for no reason. The pipeline only
# needs the five time windows so each part can be sampled and reviewed alone.
#
# Prints a TSV the workflow reads, plus ready-to-run sample-frames.sh commands.
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

VIDEO="${1:-}"
KICKOFF="${2:-0}"
PARTS="${3:-5}"

if [[ -z "$VIDEO" ]]; then
  echo "usage: scripts/split-parts.sh <video> [kickoff-s] [parts]" >&2
  echo "  kickoff-s: seconds of pre-match on the tape. Default 0." >&2
  exit 1
fi

cp_need_ffmpeg
cp_need_file "$VIDEO"

TOTAL="$(cp_duration "$VIDEO")"
PLAY="$(cp_calc "$TOTAL - $KICKOFF")"

case "$PLAY" in
  -*) cp_die "kickoff ($KICKOFF s) is after the end of the file ($TOTAL s)" ;;
esac

LEN="$(cp_calc "$PLAY / $PARTS")"

echo "# video: $VIDEO"
echo "# duration_s: ${TOTAL%.*}   kickoff_s: $KICKOFF   play_s: ${PLAY%.*}   parts: $PARTS"
echo "# each part is $(cp_mmss "$LEN") long"
echo "#"
echo "# Split on duration, not on 'when things happened'. Finding the moments is"
echo "# the model's job after the cut, one part at a time."
echo
printf "part\tstart_s\tend_s\tstart_mmss\tend_mmss\n"

i=1
while [[ "$i" -le "$PARTS" ]]; do
  s="$(cp_calc "$KICKOFF + ($i - 1) * $LEN")"
  e="$(cp_calc "$KICKOFF + $i * $LEN")"
  printf "%d\t%.2f\t%.2f\t%s\t%s\n" "$i" "$s" "$e" "$(cp_mmss "$s")" "$(cp_mmss "$e")"
  i=$((i+1))
done

echo
echo "# Run these one at a time. Review each part before starting the next."
echo "# Do not carry part 1 frames into part 4."
i=1
while [[ "$i" -le "$PARTS" ]]; do
  s="$(cp_calc "$KICKOFF + ($i - 1) * $LEN")"
  e="$(cp_calc "$KICKOFF + $i * $LEN")"
  echo "scripts/sample-frames.sh \"$VIDEO\" wiki/analysis/moments/<slug>/part-$i ${s%.*} ${e%.*}"
  i=$((i+1))
done
