# ~/.config/zsh/keybinds.zsh

# 10ms na sekwencje klawiszy
KEYTIMEOUT=1

# Lepsze wyszukiwanie historii w trybie vi
bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

# Strzałki = wyszukiwanie prefixowe w historii
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search

