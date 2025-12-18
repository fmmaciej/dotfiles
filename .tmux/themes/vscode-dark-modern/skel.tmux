##### status-skeleton.tmux — formaty bez kolorów #####

# status on + interwał
set -g status on
set -g status-interval 1

# nie narzucaj tła panelom/oknom (bierz z terminala)
setw -g window-style        'bg=default'
setw -g window-active-style 'bg=default'

# style neutralne (dziedziczenie)
set -g status-style default
setw -g window-status-style default
setw -g window-status-current-style default
set -g pane-border-style default
set -g pane-active-border-style default
set -g message-style default
set -g mode-style default

# LEWY pasek: nazwa sesji
set -g status-left-length 100
# set -g status-left " #S < "

# PRAWY pasek: prefix/zoom/sync | bateria (jeśli plugin) | data+czas
set -g status-right-length 100
# set -g status-right "#{?client_prefix, PREFIX ,}#{?window_zoomed_flag, ZOOM ,}#{?pane_synchronized, SYNC ,}| #{?#{battery_percentage},#{battery_icon} #{battery_percentage} #{battery_remain} | ,}%d.%m.%Y | %H:%M:%S "

# Okna — czytelne formaty (bez kolorów)
setw -g window-status-format         " #I #W "
setw -g window-status-current-format " #I #W "

# Zegar
set -g clock-mode-style 24
