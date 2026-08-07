# qb-home-settings

My portable vim + shell + tmux + herdr settings. Clone onto a new Mac and run the installer.

## What's included

| File         | Installed to                   | Notes |
|--------------|--------------------------------|-------|
| `vimrc`      | `~/.vimrc`                     | Uses the gruvbox colorscheme (auto-cloned on install). |
| `bashrc`     | `~/.bashrc`                    | Despite the name this is **zsh** config — prompt, aliases, `set -o vi`, `$EDITOR`. |
| `tmux.conf`  | `~/.tmux.conf`                 | Mouse, focus events, vi copy mode, 50k scrollback, cwd-inheriting splits. |
| `herdr.toml` | `~/.config/herdr/config.toml`  | Theme + keybindings for [herdr](https://herdr.dev). |

`tmux.conf` and `herdr.toml` are deliberately kept in sync: herdr owns the
keybinding scheme and tmux follows it, so the same keys mean the same thing in
both. See the "Aligned with herdr" block in `tmux.conf` for the mapping. If you
change a binding in one, change it in the other.

> **Why "bashrc" holds zsh syntax:** the login shell on this setup is zsh, and
> `~/.zshrc` does `source ~/.bashrc`. The installer wires that up automatically.

## Install on a new MacBook

```sh
git clone <this-repo-url> ~/qb-home-settings
cd ~/qb-home-settings
./install.sh
```

Then open a new terminal (or `source ~/.zshrc`).

The installer:
- Symlinks `~/.vimrc`, `~/.bashrc`, `~/.tmux.conf` and `~/.config/herdr/config.toml`
  to this repo (so `git pull` updates them). Only herdr's config *file* is linked,
  never the whole `~/.config/herdr` directory — that also holds sockets, logs and
  session state at runtime.
- Backs up any existing files to `<file>.backup-<timestamp>` first.
- Clones the gruvbox colorscheme into `~/.vim/pack/colors/start/gruvbox`.
- Adds `source ~/.bashrc` to `~/.zshrc` if it isn't already there.
- Is safe to re-run.

## Tool dependencies (optional)

`bashrc` sources `~/.cargo/env` **only if it exists**, so nothing errors on a
fresh machine. If you later install rust (and uncomment the uv line for
`~/.local/bin/env`), those integrations activate automatically.

`tmux.conf` is inert until tmux itself is installed (`brew install tmux`); the
symlink is harmless either way. The same goes for `herdr.toml` and herdr.

Note that `herdr config reset-keys` moves `config.toml` aside and writes a fresh
one, which would replace the symlink with a real file. Re-run `./install.sh`
afterwards to relink.

This package intentionally does **not** carry the full original shell chain
(`.zshenv`, `.zprofile` with Homebrew/nvm/postgres). Install those tools
separately on the new machine as needed.
