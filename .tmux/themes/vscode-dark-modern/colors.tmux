##### vscode-dark-modern.colors.tmux — kolory (WezTerm-aware) #####

# Truecolor + kształt kursora (raz w całej konfiguracji)
set -ag terminal-overrides ',xterm*:Tc,Ss=\E[2 q:Se=\E[2 q'

# Wstrzyknij kolory literalnie (tmux nie rozwija #{…} w stylach)
run-shell -b '
  BG="${THEME_BG:-#1e1e1e}";
  FG="${THEME_FG:-#d4d4d4}";
  ACC="${THEME_ACCENT:-#007acc}";
  DIM="${THEME_DIM_FG:-#858585}";
  BOR="${THEME_BORDER:-#3c3c3c}";

  # udostępnij też jako @vars do status-left/right (tam działa format)
  tmux set -gq @bg "$BG";
  tmux set -gq @fg "$FG";
  tmux set -gq @accent "$ACC";
  tmux set -gq @dimfg "$DIM";
  tmux set -gq @border "$BOR";

  # status bar
  tmux set  -gq status-style "fg=$FG,bg=$BG";

  # okna
  tmux setw -gq window-status-style          "fg=$DIM,bg=$BG";
  tmux setw -gq window-status-current-style  "fg=#ffffff,bg=$ACC,bold";

  # ramki paneli
  tmux set  -gq pane-border-style        "fg=$BOR";
  tmux set  -gq pane-active-border-style "fg=$ACC";

  # komunikaty / copy-mode
  tmux set  -gq message-style "fg=$FG,bg=#252526";
  tmux set  -gq mode-style    "fg=$FG,bg=#252526";

  # zegar
  tmux set  -gq clock-mode-colour "$ACC";
'

# (opcjonalnie) kolor w treści paska:
set -g status-left  "#[fg=#{@dimfg},bg=#{@bg},bold] #S #[default]"
set -g status-right "#{?client_prefix,#[fg=#{@accent}] PREFIX ,}#{?window_zoomed_flag,#[fg=#{@accent}] ZOOM ,}#{?pane_synchronized,#[fg=#{@accent}] SYNC ,}#[fg=#{@dimfg}]│ #[fg=#{@fg}]#{?#{battery_percentage},#{battery_icon} #{battery_percentage} #{battery_remain} │ ,}%d.%m.%Y | %H:%M:%S "

