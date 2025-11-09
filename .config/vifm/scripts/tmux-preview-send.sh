#!/usr/bin/env bash
set -euo pipefail

SESSION="$(tmux display-message -p '#S')"
pane_id="${TMUX_PREVIEW_PANE:-}"
if [[ -z "$pane_id" ]]; then
  pane_id="$(tmux list-panes -a -F '#{session_name} #{pane_id} #{pane_title}' \
    | awk -v s="$SESSION" '$1==s && $3=="PREVIEW" {print $2; exit}')"
fi

# jeśli nadal brak – spróbuj utworzyć
if [[ -z "$pane_id" ]]; then
  pane_id="$(~/.config/vifm/scripts/tmux-preview-pane.sh)"
fi

# wyślij ścieżkę (jako literal)
file="$1"
tmux send-keys -t "$pane_id" "$(printf "%q" "$file")" Enter
sleep 2
tmux last-pane

