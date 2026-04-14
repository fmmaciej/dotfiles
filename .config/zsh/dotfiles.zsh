# Dotfiles helpers

export DOTFILES_GIT_DIR="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
export DOTFILES_WORK_TREE="${DOTFILES_WORK_TREE:-$HOME}"
export DOTFILES_VIEW_DIR="${DOTFILES_VIEW_DIR:-$HOME/.vscode-dotfiles}"

dot() {
  /usr/bin/git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$DOTFILES_WORK_TREE" "$@"
}

dot-help() {
  cat <<'EOF'
dotfiles helpers

  dot status          show dotfiles repo status
  dot diff            show unstaged changes
  dot add <path>      track a file from $HOME
  dot commit          commit staged dotfiles changes
  dot-sync            recreate ~/.vscode-dotfiles symlink view
  dot-code            open ~/.vscode-dotfiles in VS Code

Notes:
  ~/.dotfiles is the Git metadata directory.
  ~/.vscode-dotfiles is disposable and can be rebuilt with dot-sync.
EOF
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
