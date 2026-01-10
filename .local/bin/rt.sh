#!/usr/bin/env bash

XMLRPC="$HOME/.local/bin/rtxml"
RTORRENT_DIR="$HOME/.rtorrent"

WATCH_DIR="$RTORRENT_DIR/watch"

usage() {
  echo "usage:"
  echo "  rt add file.torrent"
  echo "  rt magnet link"
  echo "  rt start"
  echo "  rt stop"
  echo "  rt rm"
}

rpc() {
  "$XMLRPC" "$@"
}

list() {
  rpc download_list '' |
    while read -r hash; do
      name=$(rpc d.name "$hash" | tr -d '"')
      percent=$(rpc d.completed_chunks "$hash")
      total=$(rpc d.size_chunks "$hash")

      if [[ "$total" -gt 0 ]]; then
        prog=$((percent * 100 / total))
      else
        prog=0
      fi

      printf "%s | %3s%% | %s\n" "$hash" "$prog" "$name"
    done
}

sel() {
  list | fzf --delimiter='|' --with-nth=2,3 \
    --preview 'echo HASH: {1} | cut -c1-8' \
    --prompt="rtorrent> "
}

PARAM="$1"

case "$PARAM" in
  add)
    cp "$2" "$WATCH_DIR"
    ;;
  magnet)
    uri="${*:2}"
    rpc load.start_verbose '' "$uri" 2>/dev/null \
      || rpc load.start '' "$uri" 2>/dev/null \
      || rpc load.normal '' "$uri"
    ;;
  start)
    sel | awk '{print $1}' | while read -r h; do rpc d.start "$h"; done
    ;;
  stop)
    sel | awk '{print $1}' | while read -r h; do rpc d.stop "$h"; done
    ;;
  rm)
    sel | awk '{print $1}' | while read -r h; do rpc d.erase "$h"; done
    ;;
  *)
    usage
    ;;
esac
