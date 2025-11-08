# ~/.zprofile — rzeczy uruchamiane PRZY LOGOWANIU
#

# Pyenv: login
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

