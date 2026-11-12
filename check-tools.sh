#!/usr/bin/env bash

# Manually maintained command list for the macOS configuration.
programs=(
  brew git stow
  bash zsh
  fzf fd rg bat
  tmux vim yazi urlview
  wezterm opencode code
  python3 just rsync
  rtorrent cmus
  curl pbcopy pbpaste open
)

missing=0

for program in "${programs[@]}"; do
  if command -v "$program" >/dev/null 2>&1; then
    printf 'OK       %s\n' "$program"
  else
    printf 'MISSING  %s (not in PATH)\n' "$program"
    missing=1
  fi
done

exit "$missing"
