# NOTE: despite the name, this file uses zsh syntax. It is sourced by ~/.zshrc
# (see README). The zsh prompt escapes and `autoload` will not work in real bash.

autoload -U colors && colors

export PS1="%{$fg[green]%}%n@%m%{$reset_color%}: [ %{$fg[blue]%}%~%{$reset_color%} ]
%{$fg[green]%}$%{$reset_color%} "

alias ..='cd ..'
alias ls='ls -GH'
alias ll='ls -l'
alias lla='ls -la'

set -o vi

export VISUAL=vim EDITOR=vim

# herdr 0.8.0 leaves the Kitty keyboard protocol on when its client exits, so
# after `prefix+d` the terminal is left with flags=15. Every later keystroke then
# arrives CSI-u encoded, and the leading ESC drops zsh into vicmd (`set -o vi`
# above), where `:` runs execute-named-cmd -- hence a stuck `execute:` prompt.
#
# Popping (`CSI < u`) does NOT fix this, which is why the first version of this
# wrapper had no effect: herdr turns the protocol on with `CSI = <flags> ; 1 u`,
# a *set*, and never pushes. The whole binary contains exactly two keyboard
# sequences -- `\e[=<flags>;1u` and a `\e[<1u` sitting in the same teardown
# string pool as the mouse/bracketed-paste resets -- and no `\e[><flags>u` push
# anywhere. So the stack is empty at exit and both herdr's pop and ours are
# no-ops. Setting the flags back to 0 is what actually restores legacy encoding.
# Drop this once herdr resets the flags itself.
# The tty guard keeps escape bytes out of `herdr <subcommand> | jq` JSON output.
herdr() {
  command herdr "$@"
  local rc=$?
  [ -t 1 ] && printf '\033[=0;1u'
  return $rc
}

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
