# qb-home-settings

My portable vim + shell + tmux + herdr + Claude Code settings. Clone onto a new
Mac and run the installer.

## What's included

| File | Installed to | Mode | Notes |
|------|--------------|------|-------|
| `vimrc`      | `~/.vimrc`                    | link | Uses the gruvbox colorscheme (auto-cloned on install). |
| `bashrc`     | `~/.bashrc`                   | link | Despite the name this is **zsh** config — prompt, aliases, `set -o vi`, `$EDITOR`. |
| `tmux.conf`  | `~/.tmux.conf`                | link | Mouse, focus events, vi copy mode, 50k scrollback, cwd-inheriting splits. |
| `herdr.toml` | `~/.config/herdr/config.toml` | link | Theme + keybindings for [herdr](https://herdr.dev). |
| `claude-statusline.sh`       | `~/.claude/statusline.sh`       | link | Model name, token counts, colored context bar, git branch/dirty state. Needs `jq`. |
| `claude-settings.json`       | `~/.claude/settings.json`       | copy | `skipAutoPermissionPrompt`, `voiceEnabled`, `curl` allowed, `defaultMode: auto`, plugin marketplaces, status line. `context7` MCP kept disabled. Model and effort level deliberately unset so the client defaults apply. |

## Two install modes

Most files are **symlinked**, so `git pull` updates them live. The Claude
`settings.json` is **copied** instead, because Claude Code and herdr both write
into `~/.claude/settings.json` at runtime — `/effort` writes `effortLevel`, auto
mode writes an `autoMode.environment` block, and herdr installs a `SessionStart`
hook. Under a symlink every one of those lands in this repo's working tree and
leaves it permanently dirty.

The trade-off: copied files are installed once, then left alone. On re-run the
installer reports `skip … exists and differs` and prints a `diff` command rather
than clobbering whatever the tools have since written. To force a fresh copy,
delete the destination and re-run.

No Claude sound hooks are configured, on purpose: `afplay` routes to the default
output device, which pulls Bluetooth headphones away from whatever else they're
playing.

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
- Symlinks `~/.vimrc`, `~/.bashrc`, `~/.tmux.conf`, `~/.config/herdr/config.toml`
  and `~/.claude/statusline.sh` to this repo (so `git pull` updates them). Only
  herdr's config *file* is linked, never the whole `~/.config/herdr` directory —
  that also holds sockets, logs and session state at runtime.
- Copies `claude-settings.json` into `~/.claude/` (see *Two install modes*).
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

`claude-statusline.sh` needs **`jq`** (`brew install jq`).

This package intentionally does **not** carry the full original shell chain
(`.zshenv`, `.zprofile` with Homebrew/nvm/postgres). Install those tools
separately on the new machine as needed.

## Tool-managed content is not vendored here

Where another tool owns a file, this repo records the command to regenerate it
rather than keeping a snapshot that goes stale. A copy would drift from whatever
version the tool currently installs, and in some cases the tool overwrites it
anyway.

| Not in this repo | Get it with |
|------------------|-------------|
| herdr's `SessionStart` hook in `~/.claude/settings.json`, and `~/.claude/hooks/herdr-agent-state.sh` | `herdr integration install claude` |
| Claude Code plugins/skills (e.g. the `mattpocock` marketplace) | Declared in `claude-settings.json`; Claude Code installs them on first run |
| `autoMode.environment` in `~/.claude/settings.json` | Machine-local. Left unset so auto mode falls back to trusting only the working directory and the current repo's remotes. |
| `~/.claude/settings.local.json` | Machine-local by design — the "local" settings tier exists for per-machine overrides, and Claude Code gitignores it. Write one by hand if a machine needs to override something. |

Account state and runtime data are excluded for the usual reasons: `~/.claude.json`
holds OAuth tokens, and `~/.claude/`'s `history/`, `projects/`, `sessions/`,
`shell-snapshots/`, `telemetry/`, `tasks/`, `plans/`, `cache/` and `plugins/`
directories all regenerate on their own.
