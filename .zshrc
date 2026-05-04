# ~/.zshrc — interaktywne: oh-my-zsh, pluginy, bindy, fzf, itp.
#

# Historia i znaki czasu
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000

setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt NO_SHARE_HISTORY        # historia per-shell
setopt NO_BEEP

setopt nosharehistory
HIST_STAMPS="%y.%m.%d %T"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_FILES="${HOME}/.config/zsh"
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

# Prywatne zmienne lokalne: sekrety, tokeny, lokalne sciezki.
[ -r "${ZSH_FILES}/env.local" ] && source "${ZSH_FILES}/env.local"

# Numerowane moduly interaktywne, ladowane w kolejnosci leksykalnej.
for f in ${ZSH_FILES}/[0-9][0-9]-*.zsh(N); do
  [ -r "$f" ] && source "$f"
done
