#!/usr/bin/env bash
#
# Installs vim + shell + tmux + herdr + claude dotfiles into $HOME.
# Existing files are backed up (never overwritten) before linking.
# Safe to re-run.
#
# Two install modes, chosen per file:
#   link()  static configs no tool rewrites -- symlinked, so `git pull` updates them.
#   copy()  files the tool itself writes to (Claude's settings.json). Symlinking
#           those would leave this repo permanently dirty, so they are copied on
#           first install and then LEFT ALONE. See README.

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

# Copy, but never clobber a file the tool has since edited. Claude Code writes
# effortLevel/autoMode into settings.json and herdr installs a SessionStart hook
# there, so an unconditional copy on re-run would silently discard both.
copy() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    mv "$dest" "$dest.backup-$TS"
    echo "backup $dest (was a symlink) -> $dest.backup-$TS"
  elif [ -e "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      echo "ok    $dest already up to date"
    else
      echo "skip  $dest exists and differs -- left alone"
      echo "      diff:  diff '$dest' '$src'"
    fi
    return
  fi
  cp "$src" "$dest"
  echo "copy  $dest <- $src"
}

# 1. dotfiles
link "$DOTFILES_DIR/vimrc"     "$HOME/.vimrc"
link "$DOTFILES_DIR/bashrc"    "$HOME/.bashrc"
link "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# 2. XDG config files. Only the config file is linked, never the whole herdr
#    directory -- it also holds sockets, logs and session state at runtime.
mkdir -p "$HOME/.config/herdr"
link "$DOTFILES_DIR/herdr.toml" "$HOME/.config/herdr/config.toml"

# 2b. Claude Code. statusline.sh is ours alone, so it is linked. settings.json
#     is copied: Claude Code and herdr both write into it at runtime (see
#     copy() above). settings.local.json is deliberately not managed here --
#     that tier is for machine-specific overrides and Claude Code gitignores it.
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude-statusline.sh" "$HOME/.claude/statusline.sh"
copy "$DOTFILES_DIR/claude-settings.json" "$HOME/.claude/settings.json"

# 3. vim gruvbox colorscheme (referenced by vimrc)
GRUVBOX="$HOME/.vim/pack/colors/start/gruvbox"
if [ -d "$GRUVBOX/.git" ]; then
  echo "ok    gruvbox already installed"
else
  mkdir -p "$(dirname "$GRUVBOX")"
  git clone --depth 1 https://github.com/morhetz/gruvbox.git "$GRUVBOX"
  echo "clone gruvbox -> $GRUVBOX"
fi

# 4. macOS login shell is zsh, which does NOT read .bashrc on its own.
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
