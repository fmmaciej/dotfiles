#!/usr/bin/env bash

# MSYS2-side availability check only; it does not install or run these tools.
programs=(bash perl stow cygpath)
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
