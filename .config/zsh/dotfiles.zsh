# Dotfiles helpers

export DOTFILES_GIT_DIR="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
export DOTFILES_WORK_TREE="${DOTFILES_WORK_TREE:-$HOME}"
export DOTFILES_VIEW_DIR="${DOTFILES_VIEW_DIR:-$HOME/.vscode-dotfiles}"

dot() {
  /usr/bin/git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$DOTFILES_WORK_TREE" "$@"
}

dot-code() {
  if [[ ! -d "$DOTFILES_VIEW_DIR" ]]; then
    dot-sync || return
  fi

  code "$DOTFILES_VIEW_DIR"
}

dot-sync() {
  if [[ "$DOTFILES_VIEW_DIR" != "$HOME/.vscode-dotfiles" ]]; then
    print -u2 "dot-sync: refusing to replace unexpected view dir: $DOTFILES_VIEW_DIR"
    return 1
  fi

  (
    cd "$DOTFILES_WORK_TREE" || exit 1
    rm -rf "$DOTFILES_VIEW_DIR"
    mkdir -p "$DOTFILES_VIEW_DIR"
    dot ls-files -z | while IFS= read -r -d '' file; do
      mkdir -p "$(dirname "$DOTFILES_VIEW_DIR/$file")"
      ln -sf "$DOTFILES_WORK_TREE/$file" "$DOTFILES_VIEW_DIR/$file"
    done
  )
}
