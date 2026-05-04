# FZF

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--layout=reverse --inline-info"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers {}"'

if command -v brew >/dev/null 2>&1; then
  FZF_PREFIX="$(brew --prefix)/opt/fzf"
  [ -f "$FZF_PREFIX/shell/completion.zsh" ] && source "$FZF_PREFIX/shell/completion.zsh"
  [ -f "$FZF_PREFIX/shell/key-bindings.zsh" ] && source "$FZF_PREFIX/shell/key-bindings.zsh"
fi
