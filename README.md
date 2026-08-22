# qb-home-settings

Portable vim, shell, tmux, herdr, Claude Code, and Codex settings for Linux,
macOS, and WSL.

## Install

```sh
git clone <this-repo-url> ~/qb-home-settings
cd ~/qb-home-settings
./install.sh
```

Then open a new terminal. The installer is safe to re-run.

## Settings

| File | Installed to | Mode |
|------|--------------|------|
| `vimrc` | `~/.vimrc` | link |
| `bashrc` | `~/.bashrc` | link |
| `tmux.conf` | `~/.tmux.conf` | link |
| `herdr.toml` | `~/.config/herdr/config.toml` | link |
| `claude-statusline.sh` | `~/.claude/statusline.sh` | link |
| `claude-settings.json` | `~/.claude/settings.json` | copy |
| `codex-config.toml` | `~/.codex/config.toml` | copy |

Static files are symlinked so `git pull` updates them immediately. Existing
link targets are backed up before replacement.

Claude and Codex settings are copied because both tools add runtime or
machine-local state to their installed config. Copies are installed only when
the destination is absent; later installer runs report differences without
overwriting them. Delete the destination and re-run the installer to restore
the repository version.

The Codex file is intentionally only a portable seed containing personality and
status-line preferences. Project trust, migration notices, onboarding state,
hook trust hashes, authentication, histories, databases, and caches remain
local under `~/.codex/`.

## Notes

- `bashrc` is shared by bash and zsh, so one file covers Linux, macOS, and
  WSL. Only the prompt and the `^R` binding differ between the shells; keep
  everything else in the common section. bash reads `~/.bashrc` itself, and the
  installer points `~/.zshrc` at it wherever zsh is present.
- On Linux and WSL, a *login* bash reads `~/.profile` or `~/.bash_profile`, not
  `~/.bashrc`. Every mainstream distro ships a `~/.profile` that sources
  `~/.bashrc`; if a machine does not, add that line by hand.
- The installer clones gruvbox into `~/.vim/pack/colors/start/gruvbox`.
- `tmux.conf` and `herdr.toml` share a keybinding scheme; update both when
  changing an aligned binding.
- `claude-statusline.sh` requires `jq` (`brew install jq`, `apt install jq`).
- `bashrc` defines `claude-qwen`, which runs Claude Code against the local
  Qwen3.8-27B server instead of Anthropic. Unlike everything else here it is
  **not portable**: the base URL is a Meshnet host and the token limits are
  correct only for that model. See `qb-local-llm-setup`. A plain `claude` is
  unaffected — the exports are scoped to the function.
- tmux and herdr are optional; their settings remain inert until the tools are
  installed.
- This repo deliberately excludes machine-specific `.zshenv`, `.zprofile`,
  Homebrew, nvm, and PostgreSQL setup.

## Tool-managed integrations

Regenerate tool-owned files instead of vendoring them:

| Integration | Command or source |
|-------------|-------------------|
| herdr Claude hook | `herdr integration install claude` |
| Claude plugins and skills | Declared in `claude-settings.json`; installed by Claude Code |

`~/.claude.json`, `~/.claude/settings.local.json`, and runtime data under
`~/.claude/` are intentionally not managed here. If
`herdr config reset-keys` replaces the herdr config symlink, re-run
`./install.sh` to restore it.
