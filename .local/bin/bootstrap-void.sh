#!/usr/bin/env bash
set -euo pipefail

echo "─────────────────────────────────────────────"
echo " 🧩 Bootstrap (Void Linux) – CLI deps setup  "
echo "─────────────────────────────────────────────"

need() { command -v "$1" >/dev/null 2>&1; }
pkg()  { sudo xbps-install -y "$@"; }

echo "→ Sync & upgrade system (xbps)…"
sudo xbps-install -Syu

echo "→ Core toolchain & shells…"
pkg git curl wget zsh tmux neovim \
    gcc make pkgconf clang

echo "→ Productivity & search…"
pkg fzf fd ripgrep bat eza zoxide jq \
    ncdu duf dust gdu git-delta

echo "→ Media/preview stack…"
pkg ffmpeg poppler chafa ImageMagick

echo "→ Dev runtimes…"
pkg python3 python3-pip rust cargo nodejs

echo "→ TUI/CLI extras…"
# w Void nazwy pakietów najczęściej pokrywają się 1:1
# próbujemy z repo; jeśli brak – instalujemy z cargo (fallback)
MISSING=()

# atuin
if ! need atuin; then
  if xbps-query -Rs '^atuin$' >/dev/null 2>&1; then pkg atuin; else MISSING+=("atuin"); fi
fi

# starship
if ! need starship; then
  if xbps-query -Rs '^starship$' >/dev/null 2>&1; then pkg starship; else MISSING+=("starship"); fi
fi

# yazi
if ! need yazi; then
  if xbps-query -Rs '^yazi$' >/dev/null 2>&1; then pkg yazi; else MISSING+=("yazi"); fi
fi

# glow
if ! need glow; then
  if xbps-query -Rs '^glow$' >/dev/null 2>&1; then pkg glow; else MISSING+=("glow"); fi
fi

# mosh
if ! need mosh; then
  if xbps-query -Rs '^mosh$' >/dev/null 2>&1; then pkg mosh; fi
fi

# tldr
if ! need tldr; then
  if xbps-query -Rs '^tldr$' >/dev/null 2>&1; then pkg tldr; fi
fi

# Fallbacky przez cargo (tylko dla braków)
if ((${#MISSING[@]})); then
  echo "→ Cargo fallback for: ${MISSING[*]} (if not in repo)"
  mapfile -t TO_INSTALL < <(printf '%s\n' "${MISSING[@]}" | sort -u)
  for crate in "${TO_INSTALL[@]}"; do
    case "$crate" in
      atuin)    cargo install atuin ;;
      starship) cargo install starship ;;
      yazi)     cargo install yazi-fm ;;
      glow)     cargo install glow ;;
      *)        echo "  • no cargo recipe for $crate (skip)";;
    esac
  done
fi

echo "→ fzf key-bindings/completion (zsh)…"
# Void zwykle instaluje do /usr/share/fzf/*
if [[ -n "${ZSH_VERSION:-}" ]]; then
  mkdir -p "$HOME/.zshrc.d"
  {
    echo '[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh'
    echo '[[ -f /usr/share/fzf/completion.zsh   ]] && source /usr/share/fzf/completion.zsh'
  } > "$HOME/.zshrc.d/20-fzf.zsh"
fi

echo "→ Initialize atuin/tldr (best effort)…"
if need atuin; then
  atuin import auto || true
  atuin sync || true
fi
if need tldr; then
  tldr --update || true
fi

echo "→ Create config dirs…"
mkdir -p "$HOME/.config/{yazi,vifm,wezterm,starship}" "$HOME/.local/bin"

# Opcjonalnie: WezTerm (brak w repo Void) – AppImage/flatpak/źródła:
# echo "→ (optional) Install WezTerm:"
# echo "   - AppImage: https://github.com/wez/wezterm/releases"
# echo "   - Flatpak:  flatpak install flathub org.wezfurlong.wezterm"

echo "─────────────────────────────────────────────"
echo " Done. Packages installed on Void Linux.  "
echo "─────────────────────────────────────────────"
echo
echo "Upewnij się, że Twoje dotfiles są zlinkowane."
echo "Jeśli używasz Zsh, dodaj w ~/.zshrc:  for f in ~/.zshrc.d/*.zsh; do source \"$f\"; done"

