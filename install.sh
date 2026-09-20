#!/usr/bin/env bash
#
# Installs vim + shell + tmux + herdr + Claude + Codex dotfiles into $HOME.
# Existing files are backed up (never overwritten) before linking.
# Safe to re-run.
#
# Two install modes, chosen per file:
#   link()  static configs no tool rewrites -- symlinked, so `git pull` updates them.
#   copy()  files the tools themselves write to (Claude and Codex config).
#           Symlinking those would leave this repo permanently dirty, so they
#           are copied on first install and then LEFT ALONE. See README.

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

# 2c. Codex. config.toml accumulates project trust, migration notices, and other
#     machine-local state, so install only our portable seed and let Codex own
#     the resulting file afterwards.
mkdir -p "$HOME/.codex"
copy "$DOTFILES_DIR/codex-config.toml" "$HOME/.codex/config.toml"

# 3. vim gruvbox colorscheme (referenced by vimrc)
GRUVBOX="$HOME/.vim/pack/colors/start/gruvbox"
if [ -d "$GRUVBOX/.git" ]; then
  echo "ok    gruvbox already installed"
else
  mkdir -p "$(dirname "$GRUVBOX")"
  git clone --depth 1 https://github.com/morhetz/gruvbox.git "$GRUVBOX"
  echo "clone gruvbox -> $GRUVBOX"
fi

# 4. bash reads ~/.bashrc on its own, but zsh (the macOS login shell) does not.
#    Wire it up only where zsh exists, so a bash-only Linux or WSL box does not
#    get a stray ~/.zshrc it will never read.
ZSHRC="$HOME/.zshrc"
if ! command -v zsh >/dev/null 2>&1; then
  echo "skip  no zsh on this machine -- bash reads ~/.bashrc directly"
elif [ ! -f "$ZSHRC" ]; then
  echo "source ~/.bashrc" > "$ZSHRC"
  echo "create $ZSHRC (sources ~/.bashrc)"
elif ! grep -Eq '(source|\.) +(~|"?\$HOME"?)/\.bashrc' "$ZSHRC"; then
  printf '\nsource ~/.bashrc\n' >> "$ZSHRC"
  echo "edit  added 'source ~/.bashrc' to $ZSHRC"
else
  echo "ok    $ZSHRC already sources ~/.bashrc"
fi

# 5. Anything driven over SSH -- Moshi detecting herdr, mosh launching
#    mosh-server -- resolves binaries on the NON-interactive PATH, and
#    `ssh host '<cmd>'` reads only ~/.zshenv, never ~/.zshrc or ~/.zprofile.
#    ~/.zshenv itself stays unmanaged (machine-specific cargo, nvm, Homebrew
#    setup lives there), so wire in a source line, as with ~/.zshrc above.
ZSHENV="$HOME/.zshenv"
if ! command -v zsh >/dev/null 2>&1; then
  echo "skip  no zsh on this machine -- nothing to wire into ~/.zshenv"
else
  link "$DOTFILES_DIR/zshenv-path" "$HOME/.zshenv-path"
  # Guarded: an unguarded source makes EVERY zsh -- including the scripted and
  # SSH ones this exists for -- print an error if the repo is ever moved away.
  SOURCE_LINE='[ -r "$HOME/.zshenv-path" ] && . "$HOME/.zshenv-path"'
  if [ ! -f "$ZSHENV" ]; then
    echo "$SOURCE_LINE" > "$ZSHENV"
    echo "create $ZSHENV (sources ~/.zshenv-path)"
  elif ! grep -q '\.zshenv-path' "$ZSHENV"; then
    printf '\n%s\n' "$SOURCE_LINE" >> "$ZSHENV"
    echo "edit  added '. ~/.zshenv-path' to $ZSHENV"
  else
    echo "ok    $ZSHENV already sources ~/.zshenv-path"
  fi
fi

echo
echo "Done. Open a new terminal to apply."
