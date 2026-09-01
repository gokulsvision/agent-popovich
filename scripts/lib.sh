#!/usr/bin/env bash
# lib.sh — shared helpers. Sourced by the other scripts. Not run directly.
#
# Targets bash 3.2, because that is what ships on macOS. No associative arrays,
# no `${A[@]}` on an empty array under `set -u`, no mapfile.

# Repo root, regardless of where the script was called from.
cp_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

cp_die() {
  echo "error: $*" >&2
  exit 1
}

cp_need() {
  command -v "$1" >/dev/null 2>&1 || cp_die "$1 not found. $2"
}

# ffmpeg and ffprobe are the only hard dependencies.
cp_need_ffmpeg() {
  cp_need ffmpeg "Install it: brew install ffmpeg"
  cp_need ffprobe "Install it: brew install ffmpeg"
}

cp_need_file() {
  [[ -f "$1" ]] || cp_die "file not found: $1"
}

# Seconds (float) -> MM:SS, for wiki pages. Coaching notes use MM:SS.
cp_mmss() {
  awk -v s="$1" 'BEGIN{ s=(s<0?0:s); m=int(s/60); r=s-m*60; printf "%d:%02d\n", m, r }'
}

# Float math without bc, which is not guaranteed to be installed.
cp_calc() {
  awk "BEGIN{ printf \"%.3f\n\", $1 }"
}

# Duration in seconds. Prints a float.
cp_duration() {
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$1"
}

cp_has_audio() {
  local s
  s="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=nw=1:nk=1 "$1" 2>/dev/null || true)"
  [[ -n "$s" ]]
}
