#!/usr/bin/env bash
set -euo pipefail

TITLE="PREVIEW"
SESSION="$(tmux display-message -p '#S')"

# znajdź istniejący pane z tytułem PREVIEW
pane_id="$(tmux list-panes -a -F '#{session_name} #{pane_id} #{pane_title}' 2>/dev/null \
  | awk -v s="$SESSION" -v t="$TITLE" '$1==s && $3==t {print $2; exit}')"

if [[ -z "${pane_id:-}" ]]; then
  # utwórz nowy pane po prawej (50% szerokości), wystartuj serwer
  pane_id="$(tmux split-window -h -p 50 -P -F '#{pane_id}' "bash -lc 'printf \"\033]2;$TITLE\007\"; exec ~/.config/vifm/scripts/tmux-preview-server.sh'")"
else
  # odśwież tytuł (na wszelki wypadek)
  tmux select-pane -t "$pane_id" -T "$TITLE"
fi

# zapisz id w zmiennej sesji (ułatwia wysyłanie)
tmux set-environment -t "$SESSION" TMUX_PREVIEW_PANE "$pane_id"

echo "$pane_id"

