# Interactive Bash setup for WSL/Void. No installer or remote-ssh runtime needed.
[[ $- == *i* ]] || return 0

case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"

HISTSIZE=200000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth
shopt -s histappend checkwinsize
set -o vi

alias v='vim'
alias rc='source ~/.bashrc'

dot() {
  command git -C "$HOME/.dotfiles" "$@"
}

# Yazi reports its last directory through a temporary file, never a command.
y() {
  local tmp cwd status
  tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return
  command yazi "$@" --cwd-file="$tmp"
  status=$?
  cwd=''
  IFS= read -r cwd < "$tmp" || :
  if [[ $status == 0 && -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd" || status=$?
  fi
  command rm -f -- "$tmp"
  return "$status"
}

# Use skim explicitly; do not disguise it as fzf.
z() {
  local directory
  if [[ $# == 0 ]]; then
    builtin cd -- "$HOME" || return
  else
    directory="$(command zoxide query --exclude "$PWD" -- "$@")" || return
    builtin cd -- "$directory" || return
  fi
}

zi() {
  local candidates directory
  candidates="$(command zoxide query --list -- "$@")" || return
  [[ -n "$candidates" ]] || return 1
  directory="$(printf '%s\n' "$candidates" | command sk --no-sort --prompt='directory> ')" || return
  [[ -n "$directory" ]] || return 1
  builtin cd -- "$directory" || return
}

_dotfiles_history() {
  local selected
  selected="$(builtin history | sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//' |
    awk '{ lines[NR] = $0 } END { for (i = NR; i >= 1; i--) if (!seen[lines[i]]++) print lines[i] }' |
    command sk --prompt='history> ')" || return
  READLINE_LINE="$selected"
  READLINE_POINT=${#READLINE_LINE}
}

# Select hooks and history backend once per process; rc does not duplicate them.
if [[ ${_DOTFILES_TOOLS_INITIALIZED:-0} != 1 || ${_DOTFILES_TOOLS_PID:-} != "${BASHPID:-$$}" ]]; then
  _DOTFILES_TOOLS_INITIALIZED=1
  _DOTFILES_TOOLS_PID=${BASHPID:-$$}
  _DOTFILES_LINE_EDITOR=readline
  _DOTFILES_HISTORY_BACKEND=bash
  export -n _DOTFILES_TOOLS_INITIALIZED _DOTFILES_TOOLS_PID _DOTFILES_LINE_EDITOR _DOTFILES_HISTORY_BACKEND

  if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    # shellcheck source=/dev/null
    source /usr/share/bash-completion/bash_completion
  elif [[ -r /etc/bash_completion ]]; then
    # shellcheck source=/dev/null
    source /etc/bash_completion
  fi
  complete -o filenames -d z

  export SKIM_DEFAULT_OPTIONS="${SKIM_DEFAULT_OPTIONS:---height=40% --reverse --border}"
  if command -v fd >/dev/null 2>&1; then
    export SKIM_DEFAULT_COMMAND="${SKIM_DEFAULT_COMMAND:-fd --type f --hidden --exclude .git}"
  fi
  if command -v sk >/dev/null 2>&1; then
    bind -m emacs -x '"\C-r":_dotfiles_history'
    bind -m vi-insert -x '"\C-r":_dotfiles_history'
  fi

  # Atuin >= 18.18 includes bash-preexec. Keep Bash history if hooks are absent.
  # Keep vi command-mode Ctrl-R for redo and ordinary Up/k history navigation.
  if command -v atuin >/dev/null 2>&1; then
    if _dotfiles_init="$(command atuin init bash --disable-up-arrow --disable-ctrl-r --disable-ai)" &&
      [[ -n "$_dotfiles_init" ]] && eval "$_dotfiles_init" &&
      [[ ${__atuin_initialized:-} == true && -n ${bash_preexec_imported:-} ]] &&
      declare -F atuin-bind >/dev/null; then
      if [[ -z ${ATUIN_NOBIND:-} ]]; then
        atuin-bind -m emacs '\C-r' atuin-search-emacs
        atuin-bind -m vi-insert '\C-r' atuin-search-viins
      fi
      _DOTFILES_HISTORY_BACKEND=atuin
      HISTFILE=
    else
      printf 'dotfiles: Atuin initialization failed or preexec hooks are unavailable; keeping Bash history.\n' >&2
    fi
  fi

  if command -v zoxide >/dev/null 2>&1; then
    if _dotfiles_init="$(command zoxide init bash --no-cmd)"; then
      eval "$_dotfiles_init"
    fi
  fi
  # Load the prompt last so it can share Atuin's preexec backend.
  if command -v starship >/dev/null 2>&1; then
    if _dotfiles_init="$(command starship init bash)"; then
      eval "$_dotfiles_init"
    fi
  fi
  unset _dotfiles_init

  if [[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/bash/flyline.bash ]]; then
    # shellcheck source=/dev/null
    source "${XDG_CONFIG_HOME:-$HOME/.config}/bash/flyline.bash"
    _dotfiles_flyline_initialize
    export -n _DOTFILES_FLYLINE_STATE
  fi
fi
