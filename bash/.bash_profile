# Login shells keep the user's existing environment, then load interactive setup.
if [[ -r "$HOME/.profile" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.profile"
fi

if [[ $- == *i* && -r "$HOME/.bashrc" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"
fi
