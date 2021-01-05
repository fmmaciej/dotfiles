#############################
############## Tmux Vars
##############################
#
## $(echo $USER) - shows the current username
## %a --> Day of week (Mon)
## %A --> Day of week Expanded (Monday)
#
## %b --> Month (Jan)
## %d --> Day (31)
## %Y --> Year (2017)
#
## %D --> Month/Day/Year (12/31/2017)
## %v --> Day-Month-Year (31-Dec-2017)
#
## %r --> Hour:Min:Sec AM/PM (12:30:27 PM)
## %T --> 24 Hour:Min:Sec (16:30:27)
## %X --> Hour:Min:Sec (12:30:27)
## %R --> 24 Hour:Min (16:30)
## %H --> 24 Hour (16)
## %l --> Hour (12)
## %M --> Mins (30)
## %S --> Seconds (09)
## %p --> AM/PM (AM)
#
## For a more complete list view: https://linux.die.net/man/3/strftime
#
##colour0 (black)
##colour1 (red)
##colour2 (green)
##colour3 (yellow)
##colour4 (blue)
##colour7 (white)
##colour5 colour6 colour7 colour8 colour9 colour10 colour11 colour12 colour13 colour14 colour15
#colour16 colour17
#
##D ()
##F (current window marker - *)
##H (hostname)
##I (window index)
##P ()
##S (session index)
##T (pane title)
##W (currnet task like vim if editing a file in vim or zsh if running zsh)
#
# Color key:
#   #000000 Background
#   #2a2a2a Current Line
#   #424242 Selection
#   #eaeaea Foreground
#   #969896 Comment
#   #d54e53 Red
#   #e78c45 Orange
#   #e7c547 Yellow
#   #b9ca4a Green
#   #70c0b1 Aqua
#   #7aa6da Blue
#   #c397d8 Purple

# From tmux 2.0 onward, you can use the #{?window_zoomed_flag,ZOOMTEXT,NON-ZOOM TEXT} replacement conditional in your window-status-current-format string.
# 
# For example, I use:
# #{?window_zoomed_flag,#[fg=red](,}#W#{?window_zoomed_flag,#[fg=red]),}
# 
# To surround the window name with red parenthesis when it is zoomed.


## set status bar
set -g status-bg default
setw -g window-status-current-style bg="#2a2a2a"
setw -g window-status-current-style fg="#7aa6da"

## highlight active window
setw -g window-style 'bg=#2a2a2a'
setw -g window-active-style 'bg=#000000'
setw -g pane-active-border-style ''

## highlight activity in status bar
setw -g window-status-activity-style fg="#70c0b1"
setw -g window-status-activity-style bg="#000000"

## pane border and colors
set -g pane-active-border-style bg=default
set -g pane-active-border-style fg="#424242"
set -g pane-border-style bg=default
set -g pane-border-style fg="#424242"

set -g clock-mode-colour "#7aa6da"
set -g clock-mode-style 24

set -g message-style bg="#70c0b1"
set -g message-style fg="#000000"

set -g message-command-style bg="#70c0b1"
set -g message-command-style fg="#000000"

# message bar or "prompt"
set -g message-style bg="#2d2d2d"
set -g message-style fg="#6700cc"

set -g mode-style bg="#000000"
set -g mode-style fg="colour245"
# set -g mode-style fg="#e78c45"


# left side of status bar holds "[Server name]"
set -g status-left-length 100
set -g status-left-style fg=white
set -g status-left-style bold
set -g status-left '#[fg=colour247,bg=colour0,bold] #S < #[default]'

# right side of status bar holds "[host name] (date time)"
set -g status-right-length 100
set -g status-right-style fg=white
set -g status-right-style bold
# #[fg=colour247,bg=colour0,bold]#{?window_zoomed_flag, ZOOM #[default],}
# #[fg=colour247,bg=colour0,bold]#{?client_prefix, PREFIX #[default],}
# #[fg=colour247,bg=colour0,bold]#{battery_percentage} #[default],}
# set -g status-right '#{battery_status_bg} Batt: #{battery_icon} #{battery_percentage} # #{battery_remain} | %a %h-%d %H:%M '

set -g status-right '#[fg=colour247,bg=colour0,bold]#{?client_prefix, PREFIX #[default],}#[fg=colour247,bg=colour0,bold]#{?window_zoomed_flag, ZOOM #[default],}#[fg=colour247,bg=colour0,bold]#{?pane_synchronized,#[fg=colour247] SYNC #[default],}#[fg=colour247,bg=colour0,bold]| #{battery_percentage} #{battery_remain} |#[fg=colour248,bg=colour0,bold] %d.%m.%Y |#[fg=colour247,bg=colour0,bold] %H:%M:%S '

# make background window look like white tab
set-window-option -g window-status-style bg=default
set-window-option -g window-status-style fg=white
set-window-option -g window-status-style none
set-window-option -g window-status-format '#[fg=#6700cc,bg=colour0] #I #[fg=#999999,bg=colour0] #W #[default]'

# make foreground window look like bold yellow foreground tab
set-window-option -g window-status-current-style none
set-window-option -g window-status-current-format '#[fg=#f99157,bg=colour0] #I #[fg=#cccccc,bg=colour0] #W #[default]'

# active terminal yellow border, non-active white
set -g pane-border-style bg=default
set -g pane-border-style fg="#999999"
set -g pane-active-border-style fg="#f99157"
