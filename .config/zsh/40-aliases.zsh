# Aliases

alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'

alias v='vim'
alias y='yazi'
alias less='bat'

alias rc='source ~/.zshrc'
alias rt='~/.local/bin/rt.sh'
alias cmus='~/.local/bin/gen-cmus-theme-from-wez.sh && command cmus'

# Skroty cd
unalias NOT 2>/dev/null
NOT() {
  if [[ -z "$NOTES_DIR" ]]; then
    print -u2 "NOT: ustaw NOTES_DIR w ~/.config/zsh/env.local"
    return 1
  fi

  if [[ ! -d "$NOTES_DIR" ]]; then
    print -u2 "NOT: NOTES_DIR nie wskazuje na istniejący katalog"
    return 1
  fi

  cd -- "$NOTES_DIR"
}
alias SKY="cd $HOME/Programming/03_Python/02_Projects/skylark"
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
alias bupd='brew update && omz update'
alias bupg='brew upgrade'
alias bins='brew install'
alias buni='brew uninstall'
alias bsea='brew search'
