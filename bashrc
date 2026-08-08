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

# Tool integrations: only source these if the tool is actually installed,
# so a fresh machine without rust/uv doesn't throw "no such file" errors.
#[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
