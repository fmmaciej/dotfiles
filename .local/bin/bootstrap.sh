#!/usr/bin/env bash
set -euo pipefail

echo "─────────────────────────────────────────────"
echo " 🧩 Bootstrap - install all CLI dependencies "
echo "─────────────────────────────────────────────"

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  echo "-> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "-> Updating Homebrew..."
brew update

# --- Core CLI tools ---
echo "-> Installing core packages..."
brew install \
  git curl wget zsh tmux neovim \
  fzf fd ripgrep bat eza zoxide atuin starship \
  yazi glow tldr mosh terminal-notifier \
  git-delta jq duf ncdu dust gdu smartmontools \
  ffmpeg poppler chafa imagemagick \
  python rust node

# --- Optional GUI apps (comment out if not needed) ---
# brew install --cask wezterm visual-studio-code vlc iina

# --- fzf setup (bindings + completions) ---
echo "-> Setting up fzf..."
"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --zsh

# --- atuin setup (shell history) ---
echo "-> Initializing atuin..."
atuin import auto || true
atuin sync || true

# --- tldr cache update ---
echo "-> Updating tldr cache..."
tldr --update || true

# --- Create required dirs for configs if missing ---
mkdir -p ~/.config/{yazi,vifm,wezterm,starship} ~/.local/bin

# --- Optional: Symlink dotfiles (adjust paths if needed) ---
# ln -sf ~/dotfiles/zshrc ~/.zshrc
# ln -sf ~/dotfiles/wezterm ~/.config/wezterm
# ln -sf ~/dotfiles/tmux ~/.tmux.conf
# ln -sf ~/dotfiles/vifm ~/.config/vifm
# ln -sf ~/dotfiles/yazi ~/.config/yazi

echo "─────────────────────────────────────────────"
echo " All dependencies installed successfully! "
echo "─────────────────────────────────────────────"
echo
echo "Run 'exec zsh' to reload your shell."

