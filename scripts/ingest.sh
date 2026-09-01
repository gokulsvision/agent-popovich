#!/usr/bin/env bash
# ingest.sh — copy or download a match file, probe it, print fields for the match stub.
# Usage: scripts/ingest.sh <path-or-url> <YYYY-MM-DD-opponent>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-}"
SLUG="${2:-}"

if [[ -z "$SRC" || -z "$SLUG" ]]; then
  echo "usage: scripts/ingest.sh <path-or-url> <YYYY-MM-DD-opponent>" >&2
  exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "ffprobe not found. Install ffmpeg." >&2
  exit 1
fi

DEST_DIR="$ROOT/media/matches"
mkdir -p "$DEST_DIR"

ext=""
if [[ "$SRC" =~ ^https?:// ]]; then
  ext="${SRC##*.}"
  ext="${ext%%\?*}"
  case "$ext" in
    mp4|mov|m4v|mkv|avi) ;;
    *) ext="mp4" ;;
  esac
  DEST="$DEST_DIR/${SLUG}.${ext}"
  echo "download → $DEST"
  curl -L --fail --output "$DEST" "$SRC"
else
  if [[ ! -f "$SRC" ]]; then
    echo "file not found: $SRC" >&2
    exit 1
  fi
  ext="${SRC##*.}"
  DEST="$DEST_DIR/${SLUG}.${ext}"
  if [[ "$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")" != "$DEST" ]]; then
    cp "$SRC" "$DEST"
  fi
fi

# Print a stable stub the agent can paste into the match page.
DURATION="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$DEST")"
FPS="$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nw=1:nk=1 "$DEST")"
HAS_AUDIO="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=nw=1:nk=1 "$DEST" || true)"
WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 "$DEST")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nw=1:nk=1 "$DEST")"

if [[ -n "$HAS_AUDIO" ]]; then AUDIO="yes"; else AUDIO="no"; fi
if [[ "${HEIGHT:-0}" -gt "${WIDTH:-0}" ]]; then ORIENT="vertical"; else ORIENT="landscape"; fi

echo "file: $DEST"
echo "slug: $SLUG"
echo "duration_s: $DURATION"
echo "fps: $FPS"
echo "audio: $AUDIO"
echo "width: $WIDTH"
echo "height: $HEIGHT"
echo "orientation: $ORIENT"
echo "angle: unknown  # set birds-eye | sideline | goal on the match page"
echo "status: analysis in progress"
