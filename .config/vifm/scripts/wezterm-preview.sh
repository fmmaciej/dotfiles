#!/usr/bin/env bash
# Usage: wezterm-preview.sh --image PATH | --video PATH
set -euo pipefail

mode="${1:-}"; path="${2:-}"

have() { command -v "$1" >/dev/null 2>&1; }

thumb() {
  local in="$1" out="$2"
  if have ffmpegthumbnailer; then
    ffmpegthumbnailer -i "$in" -o "$out" -s 0 -q 8 >/dev/null 2>&1
  else
    ffmpeg -y -i "$in" -vf "thumbnail,scale='min(800,iw)':'-2'" -frames:v 1 "$out" -loglevel error
  fi
}

run_imgcat() {
  # Jeśli stdout to TTY → prosto; jeśli nie → opakuj w `script` (daje pty).
  if [ -t 1 ]; then
    wezterm imgcat "$1"
  else
    # macOS/BSD `script`: plik docelowy, potem komenda
    /usr/bin/script -q /dev/null wezterm imgcat "$1"
  fi
}

case "$mode" in
  --image)
    if have wezterm; then
      run_imgcat "$path"
    elif have chafa; then
      exec chafa "$path"
    elif have identify; then
      exec identify "$path"
    else
      exec file "$path"
    fi
    ;;
  --video)
    t="$(mktemp -t vifm-thumb.XXXXXX).jpg"
    trap 'rm -f "$t"' EXIT
    thumb "$path" "$t"
    if have wezterm; then
      run_imgcat "$t"
    elif have chafa; then
      exec chafa "$t"
    else
      exec file "$path"
    fi
    ;;
  *) echo "Usage: $0 --image|--video PATH" >&2; exit 2;;
esac
