#!/usr/bin/env bash
# Serwer ma być uparty: nie wychodzi na byle błędzie.
set -u
have(){ command -v "$1" >/dev/null 2>&1; }

thumb_video () {
  local in="$1" out="$2"
  if have ffmpegthumbnailer; then
    ffmpegthumbnailer -i "$in" -o "$out" -s 0 -q 8 >/dev/null 2>&1 || true
  elif have ffmpeg; then
    ffmpeg -y -i "$in" -vf "thumbnail,scale='min(800,iw)':'-2'" -frames:v 1 "$out" -loglevel error || true
  fi
}

preview () {
  local f="$1"
  printf '\033c'  # clear
  [[ -e "$f" ]] || { echo "Nie znaleziono: $f"; return; }

  local mt
  mt="$(file -Lb --mime-type -- "$f" 2>/dev/null || echo application/octet-stream)"

  case "$mt" in
    image/*)
      if have wezterm; then wezterm imgcat -- "$f" || true
      elif have chafa; then chafa -- "$f" || true
      else file -- "$f" || true; fi
      ;;
    video/*)
      if have wezterm && (have ffmpegthumbnailer || have ffmpeg); then
        local t; t="$(mktemp -t preview.XXXXXX).jpg"
        trap 'rm -f "$t"' RETURN
        thumb_video "$f" "$t"
        [[ -s "$t" ]] && wezterm imgcat -- "$t" || file -- "$f"
      else
        if have ffprobe; then ffprobe -hide_banner -pretty -- "$f" 2>&1 | sed -n '1,25p' || true
        else file -- "$f" || true; fi
      fi
      ;;
    *)
      echo "Brak podglądu dla: $mt"
      ;;
  esac
}

# pętla wejścia: jedna ścieżka na linię
while IFS= read -r path; do
  [[ -n "$path" ]] && preview "$path"
done
