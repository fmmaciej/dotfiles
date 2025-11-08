# ~/.config/zsh/cursor.zsh

# Kształt kursora zależnie od trybu vi (zsh)
# DECSCUSR: 2 = blok stały, 6 = pionowa kreska (beam) stała
cursor_block=$'\e[2 q'
cursor_beam=$'\e[6 q'

function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 == 'block' ]]; then
    print -n -- "$cursor_block"
  else
    print -n -- "$cursor_beam"
  fi
}
function zle-line-init { print -n -- "$cursor_beam" }
zle -N zle-keymap-select
zle -N zle-line-init

