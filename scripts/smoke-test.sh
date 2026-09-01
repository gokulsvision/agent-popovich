#!/usr/bin/env bash
# smoke-test.sh — prove the pipeline works on this machine.
#
# Builds a synthetic video with known scene cuts at known times, runs the whole
# pipeline against it, and asserts the timestamps come back correct.
#
# This exists because the first version of this repo shipped a scene detector
# that emitted numbered jpgs and threw every timestamp away, and a contact sheet
# that silently showed only the first 100 seconds of an 18-minute part. Both
# looked fine until someone checked. Run this after touching scripts/.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(cp_root)"
cd "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
check() {
  if [[ "$2" == "$3" ]]; then
    printf "  ok    %s\n" "$1"; pass=$((pass+1))
  else
    printf "  FAIL  %s\n         expected %s, got %s\n" "$1" "$3" "$2"; fail=$((fail+1))
  fi
}

echo "Coach Popovich smoke test"
echo

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "  ffmpeg missing. Cannot run. brew install ffmpeg"
  exit 1
fi

# ---------------------------------------------------------------------------
# Fixture: six 10-second colour blocks. Scene cuts at 10, 20, 30, 40, 50.
# Colour per block lets us prove a frame named t45s really is from 0:45.
# ---------------------------------------------------------------------------
echo "Building fixture (60s, cuts every 10s)"
i=1
: > "$TMP/list.txt"
for c in red blue green yellow white black; do
  ffmpeg -hide_banner -loglevel error -f lavfi -i "color=c=$c:s=320x180:r=15:d=10" \
    -f lavfi -i "sine=frequency=400:duration=10" \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -shortest \
    -y "$TMP/seg$i.mp4" 2>/dev/null
  echo "file 'seg$i.mp4'" >> "$TMP/list.txt"
  i=$((i+1))
done
ffmpeg -hide_banner -loglevel error -f concat -safe 0 -i "$TMP/list.txt" -c copy -y "$TMP/match.mp4" 2>/dev/null

DUR="$(cp_duration "$TMP/match.mp4")"
check "fixture duration is 60s" "${DUR%.*}" "60"

echo
echo "split-parts.sh"
SPLIT="$("$ROOT/scripts/split-parts.sh" "$TMP/match.mp4" 2>/dev/null)"
check "five parts" "$(printf '%s\n' "$SPLIT" | awk -F'\t' '$1 ~ /^[0-9]+$/' | wc -l | tr -d ' ')" "5"
check "part 1 starts at 0" "$(printf '%s\n' "$SPLIT" | awk -F'\t' '$1=="1"{printf "%d", $2}')" "0"
check "part 5 ends at 60" "$(printf '%s\n' "$SPLIT" | awk -F'\t' '$1=="5"{printf "%d", $3}')" "60"

# Kickoff offset must shift every window.
SPLIT2="$("$ROOT/scripts/split-parts.sh" "$TMP/match.mp4" 10 2>/dev/null)"
check "kickoff 10s shifts part 1" "$(printf '%s\n' "$SPLIT2" | awk -F'\t' '$1=="1"{printf "%d", $2}')" "10"

echo
echo "sample-frames.sh — whole file"
"$ROOT/scripts/sample-frames.sh" "$TMP/match.mp4" "$TMP/all" 2>/dev/null >/dev/null
check "scene cuts found" "$(awk 'NR>1' "$TMP/all/scene.tsv" | wc -l | tr -d ' ')" "4"
# A cut is reported on the first frame of the new scene, so it lands a frame or
# two after the boundary. Assert within 1 second, not exact equality.
check "cut near 10s detected" "$(awk -F'\t' 'NR>1 && $1+0>=10 && $1+0<11' "$TMP/all/scene.tsv" | wc -l | tr -d ' ')" "1"
check "cut near 30s detected" "$(awk -F'\t' 'NR>1 && $1+0>=30 && $1+0<31' "$TMP/all/scene.tsv" | wc -l | tr -d ' ')" "1"
check "audio detected" "$([[ -s "$TMP/all/audio.tsv" ]] && echo yes || echo no)" "yes"
check "candidates written" "$([[ -s "$TMP/all/candidates.tsv" ]] && echo yes || echo no)" "yes"

echo
echo "sample-frames.sh — offset window 25s to 55s"
# The bug that made this repo lie: an offset window reported part-relative times,
# so a moment at 0:30 was written down as 0:05.
"$ROOT/scripts/sample-frames.sh" "$TMP/match.mp4" "$TMP/win" 25 55 2>/dev/null >/dev/null
check "timestamps are absolute, not window-relative" \
  "$(awk -F'\t' 'NR>1{printf "%d ", $1}' "$TMP/win/scene.tsv" | tr -d ' ')" "3050"
check "first frame is t25s" "$([[ -f "$TMP/win/frames/t25s-0-25.jpg" ]] && echo yes || echo no)" "yes"
check "no frame before the window" \
  "$(find "$TMP/win/frames" -name 't[0-9].jpg' -o -name 't1?s-*.jpg' 2>/dev/null | wc -l | tr -d ' ')" "0"

echo
echo "Contact sheet coverage"
# An 18-minute part at a fixed 10x10 tile used to drop everything after 100s.
"$ROOT/scripts/sample-frames.sh" "$TMP/match.mp4" "$TMP/cov" 0 60 2 2>/dev/null >/dev/null
SHEETS="$(find "$TMP/cov/sheets" -name 'sheet-*.jpg' | wc -l | tr -d ' ')"
LAST="$(awk -F'\t' '!/^#/{last=$3} END{printf "%d", last}' "$TMP/cov/sheets/MAP.tsv")"
check "at least one sheet" "$([[ "${SHEETS:-0}" -ge 1 ]] && echo yes || echo no)" "yes"
check "sheet map reaches end of window" "$([[ "${LAST:-0}" -ge 56 ]] && echo yes || echo no)" "yes"

echo
echo "cut-moment.sh — goal window at 45s"
"$ROOT/scripts/cut-moment.sh" "$TMP/match.mp4" "$TMP/m" 45 5 8 2>/dev/null >/dev/null
check "clip exists" "$(find "$TMP/m" -name 'clip-*.mp4' | wc -l | tr -d ' ')" "1"
check "still named by absolute time" "$([[ -f "$TMP/m/t45s-0-45.jpg" ]] && echo yes || echo no)" "yes"

# The real proof: t45s must be WHITE (block 40-50s), not red (block 0-10s).
px() { ffmpeg -hide_banner -loglevel error -i "$1" -vf "scale=1:1,format=rgb24" -f rawvideo - 2>/dev/null | xxd -p | head -1 | cut -c1-6; }
check "t45s frame is white (40-50s block)" "$(px "$TMP/m/t45s-0-45.jpg")" "ffffff"
if [[ -f "$TMP/m/t52s-0-52.jpg" ]]; then
  check "t52s frame is black (50-60s block)" "$(px "$TMP/m/t52s-0-52.jpg")" "000000"
fi
if [[ -f "$TMP/all/frames/t4s-0-04.jpg" ]]; then
  check "t4s frame is red (0-10s block)" "$(px "$TMP/all/frames/t4s-0-04.jpg")" "fe0000"
fi

echo
echo "wiki.py"
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT/scripts/wiki.py" check >/dev/null 2>&1
  check "wiki check exits clean" "$?" "0"
  BEFORE="$(python3 "$ROOT/scripts/wiki.py" backlinks 2>&1 | grep -o '[0-9]* page' | head -1)"
  AFTER="$(python3 "$ROOT/scripts/wiki.py" backlinks 2>&1 | grep -o '[0-9]* page' | head -1)"
  check "backlinks are idempotent" "$AFTER" "0 page"
else
  echo "  skip  python3 missing"
fi

echo
if [[ "$fail" -gt 0 ]]; then
  echo "$pass passed, $fail FAILED"
  exit 1
fi
echo "$pass passed. Pipeline timestamps are correct."
exit 0
