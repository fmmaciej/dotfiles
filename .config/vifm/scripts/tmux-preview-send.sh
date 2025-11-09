#!/usr/bin/env bash
set -euo pipefail

SESSION="$(tmux display-message -p '#S')"
TITLE="PREVIEW"

file="${1:-}"
[[ -z "$file" || ! -e "$file" ]] && exit 0

# 1) typ MIME
mt="$(file -Lb --mime-type -- "$file" 2>/dev/null || echo application/octet-stream)"

# 2) jeśli to NIE obraz/video -> nic nie rób
case "$mt" in
  image/*|video/*) ;;           # ok, robimy preview
  *) exit 0 ;;                  # cicho wychodzimy
esac

# 3) znajdź albo utwórz pane PREVIEW (tylko teraz – bo wiemy, że to media)
pane_id="${TMUX_PREVIEW_PANE:-}"
if [[ -z "$pane_id" ]]; then
  pane_id="$(tmux list-panes -a -F '#{session_name} #{pane_id} #{pane_title}' 2>/dev/null \
    | awk -v s="$SESSION" -v t="$TITLE" '$1==s && $3==t {print $2; exit}')"
fi

if [[ -z "$pane_id" ]]; then
  pane_id="$(~/.config/vifm/scripts/tmux-preview-pane.sh)"
fi

# 4) wyślij ścieżkę do serwera podglądu i wróć fokusem do vifm
tmux send-keys -t "$pane_id" "$(printf "%q" "$file")" Enter

tmux last-pane
sleep 0.5
tmux last-pane
