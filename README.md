# qb-home-settings

My portable vim + shell + tmux settings. Clone onto a new Mac and run the installer.

## What's included

| File        | Installed to   | Notes |
|-------------|----------------|-------|
| `vimrc`     | `~/.vimrc`      | Uses the gruvbox colorscheme (auto-cloned on install). |
| `bashrc`    | `~/.bashrc`     | Despite the name this is **zsh** config — prompt, aliases, `set -o vi`. |
| `tmux.conf` | `~/.tmux.conf`  | Mouse scroll/select + focus events (so vim's `autoread` works inside tmux). |

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
- Symlinks `~/.vimrc`, `~/.bashrc` and `~/.tmux.conf` to this repo (so `git pull` updates them).
- Backs up any existing files to `<file>.backup-<timestamp>` first.
- Clones the gruvbox colorscheme into `~/.vim/pack/colors/start/gruvbox`.
- Adds `source ~/.bashrc` to `~/.zshrc` if it isn't already there.
- Is safe to re-run.

## Tool dependencies (optional)

`bashrc` sources `~/.cargo/env` **only if it exists**, so nothing errors on a
fresh machine. If you later install rust (and uncomment the uv line for
`~/.local/bin/env`), those integrations activate automatically.

`tmux.conf` is inert until tmux itself is installed (`brew install tmux`); the
symlink is harmless either way.

This package intentionally does **not** carry the full original shell chain
(`.zshenv`, `.zprofile` with Homebrew/nvm/postgres). Install those tools
separately on the new machine as needed.
