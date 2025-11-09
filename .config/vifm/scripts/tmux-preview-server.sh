#!/usr/bin/env bash
set -euo pipefail

# narzędzia opcjonalne
have() { command -v "$1" >/dev/null 2>&1; }

thumb_video () {
  local in="$1" out="$2"
  if have ffmpegthumbnailer; then
    ffmpegthumbnailer -i "$in" -o "$out" -s 0 -q 8 >/dev/null 2>&1
  else
    ffmpeg -y -i "$in" -vf "thumbnail,scale='min(800,iw)':'-2'" -frames:v 1 "$out" -loglevel error
  fi
}

preview () {
  local f="$1"
  clear

  # rozpoznaj mime
  local mt
  mt="$(file -Lb --mime-type -- "$f" 2>/dev/null || echo application/octet-stream)"

  case "$mt" in
    image/*)
      if have wezterm; then wezterm imgcat -- "$f"; else
        if have chafa; then chafa -- "$f"; else
          file -- "$f"
        fi
      fi
      ;;
    video/*)
      if have wezterm && (have ffmpegthumbnailer || have ffmpeg); then
        local t; t="$(mktemp -t preview.XXXXXX).jpg"
        trap 'rm -f "$t"' RETURN
        thumb_video "$f" "$t"
        wezterm imgcat -- "$t"
      else
        if have ffprobe; then ffprobe -hide_banner -pretty -- "$f" 2>&1 | sed -n '1,25p'
        else file -- "$f"; fi
      fi
      ;;
    application/pdf)
      if have pdftoppm && have wezterm; then
        local t; t="$(mktemp -t preview.XXXXXX).jpg"
        trap 'rm -f "$t"' RETURN
        pdftoppm -jpeg -singlefile -scale-to 1600 -- "$f" "$t" >/dev/null 2>&1 || true
        if [[ -f "$t.jpg" ]]; then wezterm imgcat -- "$t.jpg"; else file -- "$f"; fi
      else
        if have pdftotext; then pdftotext -nopgbrk -- "$f" - | sed -n '1,60p'
        else file -- "$f"; fi
      fi
      ;;
    text/*|application/json|application/xml|application/x-sh*)
      if have bat; then bat --color=always --style=numbers --paging=never -- "$f"
      else head -n 200 -- "$f"; fi
      ;;
    *)
      # spróbuj tekstowo, a jak binarne – metadane
      if have bat; then bat -A --style=plain --paging=never -- "$f" || file -- "$f"
      else file -- "$f"; fi
      ;;
  esac
}

# pętla: czeka na ścieżki (po jednej linii)
while IFS= read -r path; do
  [[ -n "$path" && -e "$path" ]] && preview "$path"
done

