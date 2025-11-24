#!/usr/bin/env bash

set -euo pipefail

# 1) Istniejace sesji
if ! tmux ls >/dev/null 2>&1; then
  exec tmux new -s main
fi

# 2) Zbuduj menu: [NEW] + lista sesji z tmux ls
choice="$(
  { echo "[NEW]  Create new session";
    tmux ls -F "#{session_name}  (#{session_windows} win)";
  } | fzf --prompt="tmux session " --border --height=40% --reverse
)"

# 3) Użytkownik anulował fzf -> bezpieczny fallback
if [ -z "${choice:-}" ]; then
  exec tmux new -s main
fi

# 4) Nowa czy istniejąca?
if [[ "$choice" == \[NEW\]* ]]; then
  read -r -p "New session name: " name
  name="${name:-main}"
  exec tmux new -s "$name"

else
  sess="${choice%%  (*}"   # utnij opis po dwóch spacjach
  exec tmux attach -t "$sess"

fi
