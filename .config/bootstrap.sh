#!/bin/bash

set -e

REPO_URL="git@github.com:twoj-login/dotfiles.git"  # ← ZMIEŃ na swoje
DOTFILES_DIR="$HOME/.dotfiles"
WORK_TREE="$HOME"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

echo "🔧 Klonuję dotfiles jako bare repo..."
git clone --bare "$REPO_URL" "$DOTFILES_DIR"

echo "🔧 Tworzę alias 'dot' tymczasowo na czas setupu..."
alias dot="/usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$WORK_TREE"

echo "🔧 Wyłączam pokazywanie nieśledzonych plików..."
dot config --local status.showUntrackedFiles no

echo "🧹 Tworzę backup istniejących plików, które kolidują z checkoutem..."
mkdir -p "$BACKUP_DIR"
dot checkout || {
  echo "⚠️ Wykryto konflikty, przenoszę pliki do $BACKUP_DIR"
  dot checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    mv "$WORK_TREE/$file" "$BACKUP_DIR/$file"
  done
}

echo "📥 Finalny checkout..."
dot checkout
dot config --local status.showUntrackedFiles no  # jeszcze raz po checkoutcie

echo "📃 Tworzę domyślny .gitignore w \$HOME..."
cat <<EOF > "$HOME/.gitignore"
.dotfiles
.cache/
.local/
.Trash/
.zsh_history
.vscode/
Downloads/
Documents/
Pictures/
Videos/
Music/
Desktop/
.gnupg/
.ssh/
EOF

echo "🛠️ Ustawiam globalny gitignore na ten plik..."
git config --global core.excludesfile "$HOME/.gitignore"

echo "✅ Dodaj alias 'dot' do ~/.zshrc jeśli jeszcze go nie masz:"
grep -q "alias dot=" "$HOME/.zshrc" || echo "alias dot='/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> "$HOME/.zshrc"

echo "🚀 Gotowe! Użyj 'dot status' żeby sprawdzić stan dotfiles"
