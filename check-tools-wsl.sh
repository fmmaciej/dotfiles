#!/usr/bin/env bash

# Manually maintained command list for the planned WSL/Void configuration.
programs=(
  bash git stow
  starship atuin
  fd sd sk rg bat
  tmux vim opencode
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
