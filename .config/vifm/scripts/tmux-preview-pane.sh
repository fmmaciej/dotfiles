#!/usr/bin/env bash
set -u

TITLE="PREVIEW"
SESSION="$(tmux display-message -p '#S')"

# spróbuj znaleźć istniejący PREVIEW w tej sesji
pane_id="$(tmux list-panes -a -F '#{session_name} #{pane_id} #{pane_title}' 2>/dev/null \
  | awk -v s="$SESSION" -v t="$TITLE" '$1==s && $3==t {print $2; exit}')"

if [[ -z "${pane_id:-}" ]]; then
  # utwórz pane po prawej (50%), *detached* (-d), ustaw tytuł
  pane_id="$(tmux split-window -hd -p 50 -P -F '#{pane_id}' \
    "bash -lc 'printf \"\033]2;$TITLE\007\"; exec ~/.config/vifm/scripts/tmux-preview-server.sh'")"
else
  tmux select-pane -t "$pane_id" -T "$TITLE"
fi

# zapamiętaj id w zmiennej sesji (bez -v, bo u Ciebie to błąd)
tmux set-environment -t "$SESSION" TMUX_PREVIEW_PANE "$pane_id"

# nie zmieniaj fokusu – zostawiamy vifm aktywny
echo "$pane_id"
