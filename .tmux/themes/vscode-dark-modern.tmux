##### VSCode Dark Modern — tmux theme (reads THEME_* from env) #####

# ——— kolory z env (WezTerm) z bezpiecznym fallbackiem ———
set -g @bg      '#{?#{env:THEME_BG},#{env:THEME_BG},#1e1e1e}'
set -g @fg      '#{?#{env:THEME_FG},#{env:THEME_FG},#d4d4d4}'
set -g @accent  '#{?#{env:THEME_ACCENT},#{env:THEME_ACCENT},#007acc}'
set -g @dimfg   '#{?#{env:THEME_DIM_FG},#{env:THEME_DIM_FG},#858585}'
set -g @border  '#{?#{env:THEME_BORDER},#{env:THEME_BORDER},#3c3c3c}'

# ——— Truecolor + kształt kursora ———
# (default-terminal ustaw tylko raz w 00-core.conf)
set -ag terminal-overrides ',xterm*:Tc,Ss=\E[2 q:Se=\E[2 q'

# ——— status bar ———
set -g status on
set -g status-interval 15
set -g status-style "fg=#{@fg},bg=#{@bg}"

# lewa strona (nazwa sesji)
set -g status-left-length 60
set -g status-left "#[fg=#{@dimfg},bg=#{@bg},bold] #S #[default]"

# prawa strona (PREFIX/ZOOM/SYNC + bateria + data)
# jeśli masz tmux-plugins/tmux-battery: #{battery_icon} #{battery_percentage} #{battery_remain}
set -g status-right-length 100
set -g status-right "#{?client_prefix,#[fg=#{@accent}] PREFIX ,}#{?window_zoomed_flag,#[fg=#{@accent}] ZOOM ,}#{?pane_synchronized,#[fg=#{@accent}] SYNC ,}#[fg=#{@dimfg}]│ #[fg=#{@fg}]#{?#{battery_percentage},#{battery_icon} #{battery_percentage} #{battery_remain} │ ,}#[fg=#{@fg}]%d.%m.%Y %H:%M "

# ——— okna ———
setw -g window-status-style "fg=#{@dimfg},bg=#{@bg}"
setw -g window-status-format " #I #W "

# aktywne okno: jasny fg + tło w kolorze akcentu (VSCode tab current)
setw -g window-status-current-style "fg=#ffffff,bg=#{@accent},bold"
setw -g window-status-current-format " #I #W "

# ——— ramki paneli ———
set -g pane-border-style "fg=#{@border}"
set -g pane-active-border-style "fg=#{@accent}"

# ——— komunikaty / copy-mode ———
set -g message-style "fg=#{@fg},bg=#252526"
set -g mode-style    "fg=#{@fg},bg=#252526"

# ——— zegar (tryb clock-mode) ———
set -g clock-mode-style 24
set -g clock-mode-colour "#{@accent}"

