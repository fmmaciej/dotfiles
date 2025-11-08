# Aliasy: macOS-friendly
alias fd='fd --hidden'
alias less='bat'
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'

# Skroty cd
alias CON="cd $HOME/.config"
alias GI="cd $HOME/Git"
alias PRO="cd $HOME/Programming"
alias BAS="cd $HOME/Programming/01_Bash"
alias CPP="cd $HOME/Programming/02_Cpp"
alias PYT="cd $HOME/Programming/03_Python"
alias RUS="cd $HOME/Programming/04_Rust"
alias DOW="cd $HOME/Downloads"
alias DOC="cd $HOME/Documents"
alias MUS="cd $HOME/Music"

# Szybkie grepki
alias todo="rg 'TODO' -A5 ~/Documents/README/TODO/todo.md"
alias buy="rg 'BUY|ORDERED' -A2 ~/Documents/README/buy/shopping_list.md"

# Homebrew
alias bup='brew update && omz update'
alias bin='brew install'
alias bun='brew uninstall'
alias bse='brew search'

# Sesyjne
alias rc='source ~/.zshrc'

# Repo dotfiles (jeśli używasz 'bare' repo)
alias dot="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias dotcode="code --git-dir=$HOME/.dotfiles --work-tree=$HOME ~/"

VSCODE_DIR=$HOME/.vscode-dotfiles

dot-sync() {
  rm -rf $VSCODE_DIR
  mkdir -p $VSCODE_DIR
  git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME \
    ls-tree -r --name-only HEAD | while read f; do
      mkdir -p "$(dirname $VSCODE_DIR/$f)"
      ln -sf "$HOME/$f" "$VSCODE_DIR/$f"
  done
}
