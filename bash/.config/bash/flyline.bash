# shellcheck shell=bash
# Default Vim-enabled editor. Called once, after history and prompt setup.

_dotfiles_flyline_history_vi() { __atuin_history --keymap-mode=vim-insert; }
_dotfiles_flyline_history_emacs() { __atuin_history --keymap-mode=emacs; }

_dotfiles_flyline_settings() {
  builtin flyline run-tutorial false &&
    builtin flyline --show-animations false --enable-easter-eggs false \
      --enable-extended-key-codes false --send-shell-integration-codes none \
      --set-mouse-mode disabled set-cursor --backend terminal &&
    builtin flyline suggestions --auto-suggest false --auto-suggest-inline false --use-flycomp false &&
    builtin flyline history --backend bash &&
    builtin flyline key --vim-mode true || return 1

  local vi_action='' emacs_action=''
  if [[ $_DOTFILES_HISTORY_BACKEND == atuin ]]; then
    if [[ -z ${ATUIN_NOBIND:-} ]]; then
      vi_action='vimInsertMode=runBashCommand(_dotfiles_flyline_history_vi)'
      emacs_action='!vimModeEnabled+editingBufferMode=runBashCommand(_dotfiles_flyline_history_emacs)'
    fi
  elif command -v sk >/dev/null 2>&1; then
    vi_action='vimInsertMode=runBashCommand(_dotfiles_history)'
    emacs_action='!vimModeEnabled+editingBufferMode=runBashCommand(_dotfiles_history)'
  fi
  if [[ -n $vi_action ]]; then
    builtin flyline key bind Ctrl+r "$vi_action" &&
      builtin flyline key bind Ctrl+r "$emacs_action" || return 1
  fi
}

_dotfiles_flyline_initialize() {
  _DOTFILES_FLYLINE_STATE=disabled
  [[ ${DOTFILES_ENABLE_FLYLINE:-1} == 1 ]] || return 0
  _DOTFILES_FLYLINE_STATE=skipped
  [[ -t 0 && -t 1 ]] || return 0
  case ${TERM:-} in ''|dumb|unknown) return 0 ;; esac
  # This first WSL profile intentionally targets only the user's Bash/ABI family.
  [[ $OSTYPE == linux-gnu* && $HOSTTYPE == x86_64 ]] || return 0
  [[ ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]} == 5.3 ]] || return 0
  [[ -z ${BLE_VERSION:-}${_ble_attached:-} ]] || return 0
  declare -F ble-attach >/dev/null && return 0
  declare -F flyline >/dev/null && return 0
  alias flyline >/dev/null 2>&1 && return 0
  local existing
  while IFS= read -r existing; do
    case $existing in 'enable flyline'|'enable -n flyline') return 0 ;; esac
  done < <(builtin enable -a)
  # Do not take over an externally/partially initialized history integration.
  [[ ${__atuin_initialized:-} != true || $_DOTFILES_HISTORY_BACKEND == atuin ]] || return 0
  if [[ $_DOTFILES_HISTORY_BACKEND == atuin ]]; then
    declare -F __atuin_history >/dev/null || return 0
  fi
  local directory="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/flyline/current"
  directory=$(builtin cd -P -- "$directory" 2>/dev/null && builtin pwd -P) || return 0
  local library="$directory/libflyline.so"
  [[ -f $library && -r $library ]] || return 0

  local old_dir=${FLYLINE_LOAD_DIR-} old_version=${FLYLINE_VERSION-}
  local had_dir=${FLYLINE_LOAD_DIR+x} had_version=${FLYLINE_VERSION+x}
  local dir_attributes version_attributes
  dir_attributes=$(declare -p FLYLINE_LOAD_DIR 2>/dev/null) || dir_attributes=''
  version_attributes=$(declare -p FLYLINE_VERSION 2>/dev/null) || version_attributes=''
  _DOTFILES_FLYLINE_STATE=failed
  if builtin enable -f "$library" flyline; then
    export FLYLINE_LOAD_DIR="${library%/*}"
    if _dotfiles_flyline_settings; then
      _DOTFILES_LINE_EDITOR=flyline
      _DOTFILES_FLYLINE_STATE=active
      return 0
    fi
    builtin enable -d flyline || {
      _DOTFILES_LINE_EDITOR=flyline
      _DOTFILES_FLYLINE_STATE=rollback-failed
      printf 'dotfiles: Flyline rollback failed; start DOTFILES_ENABLE_FLYLINE=0 bash.\n' >&2
      return 0
    }
  fi
  if [[ -n $had_dir ]]; then FLYLINE_LOAD_DIR=$old_dir; else unset FLYLINE_LOAD_DIR; fi
  if [[ -n $had_version ]]; then FLYLINE_VERSION=$old_version; else unset FLYLINE_VERSION; fi
  if [[ $dir_attributes == 'declare -'*x*' FLYLINE_LOAD_DIR'* ]]; then
    export FLYLINE_LOAD_DIR
  else
    export -n FLYLINE_LOAD_DIR
  fi
  if [[ $version_attributes == 'declare -'*x*' FLYLINE_VERSION'* ]]; then
    export FLYLINE_VERSION
  else
    export -n FLYLINE_VERSION
  fi
  printf 'dotfiles: Flyline initialization failed; using Readline.\n' >&2
  return 0
}
