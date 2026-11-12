# FZF

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--layout=reverse --inline-info"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers {}"'

# Homebrew ustawia prefiks przy logowaniu; na tym Macu używa /opt/homebrew.
# Bez uruchamiania brew przy każdym otwarciu lub przeładowaniu powłoki.
FZF_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/fzf"
if [[ -r "$FZF_PREFIX/shell/completion.zsh" ]]; then
  source "$FZF_PREFIX/shell/completion.zsh"
fi
if [[ -r "$FZF_PREFIX/shell/key-bindings.zsh" ]]; then
  source "$FZF_PREFIX/shell/key-bindings.zsh"
fi
