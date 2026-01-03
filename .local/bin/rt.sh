#!/usr/bin/env bash

RTORRENT_DIR="$HOME/.rtorrent"

RPC="http://localhost/RPC2"
SOCKET="$RTORRENT_DIR/rpc.socket"
WATCH_DIR="$RTORRENT_DIR/watch"

usage() {
  echo "usage:"
  echo "  rt add file.torrent"
  echo "  rt start"
  echo "  rt stop"
  echo "  rt rm"
}

rpc() {
  xmlrpc --unix-socket "$SOCKET" "$RPC" "$@"
}

list() {
  rpc download_list |
      tr -d '[],' |
      while read -r hash; do
	name=$(rpc d.name "$hash" | tr -d '"')
	state=$(rpc d.state "$hash")
	percent=$(rpc d.completed_chunks "$hash")
	total=$(rpc d.size_chunks "$hash")

	if [[ "$total" -gt 0 ]]; then
	  prog=$((percent * 100 / total))
	else
	  prog=0
	fi

	printf "%-8s | %3s%% | %s\n" "${hash:0:8}" "$prog" "$name"
      done
}

select() {
  list | fzf --delimiter='|' --with-nth=2,3 --prompt="rtorrent> "
}

case "$1" in
  add)
    cp "$2" "$WATCH_DIR"
    ;;
  start)
    select | awk '{print $1}' | while read h; do rpc d.start "$h"; done
    ;;
  stop)
    select | awk '{print $1}' | while read h; do rpc d.stop "$h"; done
    ;;
  rm)
    select | awk '{print $1}' | while read h; do rpc d.erase "$h"; done
    ;;
  *)
    ;;
esac

