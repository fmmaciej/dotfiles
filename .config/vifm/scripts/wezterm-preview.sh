#!/usr/bin/env bash
# Inline preview for Vifm using WezTerm (images + video thumbnails)

set -euo pipefail

MODE=""
FILE=""

usage() { echo "Usage: $(basename "$0") --image|--video <path>"; }

# --- parse args ---
if [[ $# -lt 2 ]]; then usage; exit 2; fi
MODE="$1"; shift
FILE="$*"

# unescape %c from vifm if needed
# (zwykle %c jest już bezpieczne, ale nie zaszkodzi)
FILE="${FILE/#\~/$HOME}"

have() { command -v "$1" >/dev/null 2>&1; }

img_inline() {
  # Prefer WezTerm's imgcat
  if have wezterm; then
    wezterm imgcat "$1"
    return $?
  fi
  # Fallbacks
  if have chafa; then
    chafa "$1"
    return $?
  fi
  if have viu; then
    viu -n "$1"
    return $?
  fi
  return 1
}

show_meta() {
  # Generic metadata fallback
  if have identify; then
    identify "$1" || true
  elif have file; then
    file "$1" || true
  else
    echo "$1"
  fi
}

case "$MODE" in
  --image)
    if ! img_inline "$FILE"; then
      show_meta "$FILE"
    fi
    ;;
  --video)
    # Make a temp thumbnail
    TMPPNG="$(mktemp -t vifm-thumbXXXXXX.png)"
    # Prefer ffmpegthumbnailer if available (szybki i prosty)
    if have ffmpegthumbnailer; then
      ffmpegthumbnailer -i "$FILE" -o "$TMPPNG" -s 0 -f || true
    elif have ffmpeg; then
      # 10% w głąb timeline, 960px szerokości
      DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FILE" 2>/dev/null || echo 0)
      TS=00:00:01
      if [[ "$DUR" =~ ^[0-9]+(\.[0-9]+)?$ ]] && (( $(echo "$DUR > 10" | bc -l) )); then
        # ~10% długości, ale nie za duży offset
        TS=$(printf "%02d:%02d:%02d" 0 0 "$(awk "BEGIN{printf \"%d\", $DUR*0.1}")")
      fi
      ffmpeg -loglevel error -ss "$TS" -i "$FILE" -frames:v 1 -vf "scale='min(960,iw)':-1" "$TMPPNG" || true
    fi

    if [[ -s "$TMPPNG" ]]; then
      img_inline "$TMPPNG" || ffprobe -hide_banner -pretty "$FILE" 2>&1 | sed -n '1,25p'
      rm -f "$TMPPNG"
    else
      # żadnej miniatury -> pokaż metadane
      if have ffprobe; then
        ffprobe -hide_banner -pretty "$FILE" 2>&1 | sed -n '1,25p'
      else
        show_meta "$FILE"
      fi
    fi
    ;;
  *)
    usage; exit 2;;
esac

