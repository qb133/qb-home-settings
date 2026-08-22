# Shared interactive shell config for bash and zsh, so one file covers Linux,
# macOS and WSL. Linked to ~/.bashrc, which bash reads directly; where zsh is
# the login shell the installer also has ~/.zshrc source it.
#
# Everything here must be valid in BOTH shells. Only the prompt and the key
# bindings differ -- those have no common syntax. Keep the rest shared.

# Interactive shells only. scp, rsync and `ssh host cmd` also read this file,
# and their protocols break on any stray output from it.
case $- in *i*) ;; *) return ;; esac

# Never export PS1. bash inherits an exported PS1 from the environment, so an
# exported zsh prompt makes every child bash print %n@%m and %{...%} literally.
if [ -n "$ZSH_VERSION" ]; then
  PS1='%F{green}%n@%m%f: [ %F{blue}%~%f ]
%F{green}$%f '
else
  PS1='\[\e[32m\]\u@\h\[\e[0m\]: [ \[\e[34m\]\w\[\e[0m\] ]
\[\e[32m\]\$\[\e[0m\] '
fi

alias ..='cd ..'

# BSD ls (macOS) colours with -G, GNU ls (Linux, WSL) with --color, and -G on
# GNU means something else entirely. Recent macOS accepts --color as well, so
# probe for it rather than branching on uname.
if ls --color=auto . >/dev/null 2>&1; then
  alias ls='ls -H --color=auto'
else
  alias ls='ls -GH'
fi
alias ll='ls -l'
alias lla='ls -la'

set -o vi
# bash's vi mode leaves ^R on reverse search; zsh's viins keymap binds it to
# redisplay, which does nothing. Put it back.
[ -n "$ZSH_VERSION" ] && bindkey -M viins '^R' history-incremental-search-backward

export VISUAL=vim EDITOR=vim

# Launch Claude Code against the local Qwen3.8-27B server on the RTX 5090 box
# instead of Anthropic. vLLM speaks the Anthropic protocol natively, so there is
# no proxy in the path -- ANTHROPIC_BASE_URL is the whole integration.
#
# The two CLAUDE_CODE_* limits are measurements, not preferences: Claude Code
# guesses both wrong for a model it does not recognize. Left alone it caps output
# at 32000 (only ~1.1x headroom over the 28,604 a hard turn reaches at xhigh) and
# assumes a 200000-token window, so it starts auto-compacting ~62K early.
#
# `local -x` scopes every export to this call, so a plain `claude` in the same
# shell still reaches Anthropic. See qb-local-llm-setup, SETTINGS.md section 5C.
claude-qwen() {
  local -x ANTHROPIC_BASE_URL="http://kyubok-alps.nord:8000"   # no /v1 -- Claude Code appends it
  local -x ANTHROPIC_MODEL="qwen3.8-27b"
  local -x ANTHROPIC_DEFAULT_HAIKU_MODEL="qwen3.8-27b"         # background tasks hit the local model too
  local -x CLAUDE_CODE_MAX_OUTPUT_TOKENS=40000
  local -x CLAUDE_CODE_MAX_CONTEXT_TOKENS=262144

  # Nothing starts the server automatically -- WSL2 is not up when Windows boots,
  # so a Docker restart policy can never fire. Fail here, where the cause is
  # obvious, rather than inside Claude Code as an opaque API error.
  if ! curl -sf -m 5 "$ANTHROPIC_BASE_URL/v1/models" >/dev/null 2>&1; then
    printf 'claude-qwen: no server at %s -- start it on the RTX 5090 box\n' \
      "$ANTHROPIC_BASE_URL" >&2
    return 1
  fi

  claude "$@"
}

# Tool integrations: only source these if the tool is actually installed,
# so a fresh machine without rust/uv doesn't throw "no such file" errors.
#[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
