#!/usr/bin/env bash
#
# Installs vim + shell dotfiles by symlinking them into $HOME.
# Existing files are backed up (never overwritten) before linking.
# Safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok    $dest already linked"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup-$TS"
    echo "backup $dest -> $dest.backup-$TS"
  fi
  ln -s "$src" "$dest"
  echo "link  $dest -> $src"
}

# 1. dotfiles
link "$DOTFILES_DIR/vimrc"  "$HOME/.vimrc"
link "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"

# 2. vim gruvbox colorscheme (referenced by vimrc)
GRUVBOX="$HOME/.vim/pack/colors/start/gruvbox"
if [ -d "$GRUVBOX/.git" ]; then
  echo "ok    gruvbox already installed"
else
  mkdir -p "$(dirname "$GRUVBOX")"
  git clone --depth 1 https://github.com/morhetz/gruvbox.git "$GRUVBOX"
  echo "clone gruvbox -> $GRUVBOX"
fi

# 3. macOS login shell is zsh, which does NOT read .bashrc on its own.
#    Make sure .zshrc sources it so the prompt/aliases actually load.
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
  echo "source ~/.bashrc" > "$ZSHRC"
  echo "create $ZSHRC (sources ~/.bashrc)"
elif ! grep -Eq '(source|\.) +(~|"?\$HOME"?)/\.bashrc' "$ZSHRC"; then
  printf '\nsource ~/.bashrc\n' >> "$ZSHRC"
  echo "edit  added 'source ~/.bashrc' to $ZSHRC"
else
  echo "ok    $ZSHRC already sources ~/.bashrc"
fi

echo
echo "Done. Open a new terminal (or run: source ~/.zshrc) to apply."
