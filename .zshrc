# ~/.zshrc — interaktywne: oh-my-zsh, pluginy, bindy, fzf, itp.
#

# Historia i znaki czasu (OMZ używa HIST_STAMPS, ale warto też klasyczne opcje)
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000

setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY      # dopisuj na bieżąco
setopt NO_SHARE_HISTORY        # jak w Twoim pliku: per-shell historia
setopt NO_BEEP

# Historia, zegary, drobne opcje
setopt nosharehistory
HIST_STAMPS="%y.%m.%d %T"

# Klawisze: KEYTIMEOUT=1 bywa zbyt agresywne (0.1 s). 10 = 1 s na ESC-sekwencje.
KEYTIMEOUT=10

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="frisk"
DISABLE_AUTO_UPDATE="true"

plugins=(
  colored-man-pages
  git
  vi-mode
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# Aliasy własne, fzf, kursor, pluginy – moduły
# (ładujemy tylko w shellu interaktywnym)
for f in ~/.config/zsh/*.zsh; do
  [ -r "$f" ] && source "$f"
done

