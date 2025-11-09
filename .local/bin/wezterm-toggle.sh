# ~/.local/bin/wezterm-toggle.sh
#!/usr/bin/env bash

# Sprawdź, czy WezTerm jest uruchomiony
if pgrep -x "WezTerm" >/dev/null; then
  # Jeśli WezTerm jest na wierzchu → schowaj
  front_app=$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true')
  if [[ "$front_app" == "WezTerm" ]]; then
    osascript -e 'tell application "System Events" to keystroke "h" using {command down}'
  else
    # Jeśli działa, ale nie jest aktywny → aktywuj
    osascript -e 'tell application "WezTerm" to activate'
  fi
else
  # Jeśli nie działa, uruchom go
  open -a WezTerm
fi

