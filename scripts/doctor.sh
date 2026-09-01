#!/usr/bin/env bash
# doctor.sh — can this checkout actually run the pipeline?
#
# Run this first after cloning. It answers the only question that matters:
# will the seven stages work on this machine, or not.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ROOT="$(cp_root)"
cd "$ROOT"

fail=0
warn=0
ok()   { printf "  ok    %s\n" "$1"; }
bad()  { printf "  FAIL  %s\n" "$1"; fail=$((fail+1)); }
soft() { printf "  warn  %s\n" "$1"; warn=$((warn+1)); }

echo "Coach Popovich — checkout at $ROOT"
echo
echo "Dependencies"

if command -v ffmpeg >/dev/null 2>&1; then
  ok "ffmpeg $(ffmpeg -hide_banner -version 2>/dev/null | head -1 | awk '{print $3}')"
else
  bad "ffmpeg missing. The laptop pipeline cannot run. brew install ffmpeg"
fi

if command -v ffprobe >/dev/null 2>&1; then
  ok "ffprobe"
else
  bad "ffprobe missing. brew install ffmpeg"
fi

if command -v python3 >/dev/null 2>&1; then
  ok "python3 $(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')"
else
  bad "python3 missing. scripts/wiki.py cannot run"
fi

# drawtext is absent from some Homebrew builds. The pipeline must not depend on
# it, so this is informational only.
if ffmpeg -hide_banner -filters 2>/dev/null | grep -qw drawtext; then
  ok "ffmpeg drawtext available (optional)"
else
  soft "ffmpeg has no drawtext filter. Not required: frames are named by timestamp"
fi

echo
echo "Layout"
for p in SKILL.md AGENTS.md README.md LICENSE wiki workflows scripts media/matches; do
  if [[ -e "$p" ]]; then ok "$p"; else bad "$p missing"; fi
done

for s in ingest.sh split-parts.sh sample-frames.sh cut-moment.sh lib.sh wiki.py doctor.sh; do
  if [[ -x "scripts/$s" ]]; then
    ok "scripts/$s executable"
  elif [[ -f "scripts/$s" ]]; then
    soft "scripts/$s not executable. chmod +x scripts/*.sh"
  else
    bad "scripts/$s missing"
  fi
done

echo
echo "Wiki graph"
if command -v python3 >/dev/null 2>&1 && [[ -f scripts/wiki.py ]]; then
  out="$(python3 scripts/wiki.py check 2>&1)"
  errs="$(printf '%s\n' "$out" | grep -c '^ERROR:' || true)"
  wrns="$(printf '%s\n' "$out" | grep -c '^warn:' || true)"
  pages="$(printf '%s\n' "$out" | tail -1)"
  if [[ "${errs:-0}" -eq 0 ]]; then
    ok "links resolve. $pages"
  else
    bad "$errs broken link(s). Run: python3 scripts/wiki.py check"
  fi
  [[ "${wrns:-0}" -gt 0 ]] && soft "$wrns graph warning(s). Run: python3 scripts/wiki.py check"
else
  soft "skipped, python3 or wiki.py unavailable"
fi

echo
echo "Team pages"
if [[ -f wiki/team/TEAM.md ]]; then
  if grep -qE '^- (Club / group|Format we actually play):[[:space:]]*$' wiki/team/TEAM.md; then
    soft "TEAM.md is still the template. The coach will ask you one question before advising"
  else
    ok "TEAM.md has been filled in"
  fi
fi

newest="$(find wiki/noop/logs -name '*.md' -type f 2>/dev/null | sort | tail -1)"
if [[ -z "$newest" ]]; then
  soft "no recovery logs yet. trainer-week will refuse until you paste one"
else
  ok "newest recovery log: $(basename "$newest")"
fi

echo
echo "Match video"
vids="$(find media/matches -type f \( -name '*.mp4' -o -name '*.mov' -o -name '*.m4v' -o -name '*.mkv' \) 2>/dev/null | wc -l | tr -d ' ')"
if [[ "${vids:-0}" -eq 0 ]]; then
  soft "no video in media/matches. Chat-only mode is degraded but honest"
else
  ok "$vids file(s) in media/matches"
  find media/matches -type f \( -name '*.mp4' -o -name '*.mov' -o -name '*.m4v' -o -name '*.mkv' \) 2>/dev/null | while read -r v; do
    d="$(cp_duration "$v" 2>/dev/null || echo 0)"
    printf "        %s  %s\n" "$(cp_mmss "${d:-0}")" "$(basename "$v")"
  done
fi

echo
if [[ "$fail" -gt 0 ]]; then
  echo "$fail failure(s), $warn warning(s). Fix the failures before running the pipeline."
  exit 1
fi
echo "Ready. $warn warning(s)."
echo
echo "Next: put a bird's-eye match file in media/matches/YYYY-MM-DD-opponent.mp4"
echo "then say: review this game"
exit 0
