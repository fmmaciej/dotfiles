# Git dla zwykłego repozytorium dotfiles; ścieżki zawsze względem jego rootu.

unalias dot 2>/dev/null

dot() {
  command git -C "$HOME/.dotfiles" "$@"
}
