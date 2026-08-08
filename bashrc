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

# herdr 0.8.0 does not pop the Kitty keyboard stack when its client exits, so
# after `prefix+d` the terminal is left with flags=15. Every later keystroke then
# arrives CSI-u encoded, and the leading ESC drops zsh into vicmd (`set -o vi`
# above), where `:` runs execute-named-cmd -- hence a stuck `execute:` prompt.
# `CSI < u` pops the stack. Verified against herdr-diag captures: flags go 0 -> 15
# on detach with either prefix+d or prefix+q, and everything else (bracketed
# paste, mouse, alt screen) is torn down correctly. Drop this once herdr fixes it.
# The tty guard keeps escape bytes out of `herdr <subcommand> | jq` JSON output.
herdr() {
  command herdr "$@"
  local rc=$?
  [ -t 1 ] && printf '\033[<u'
  return $rc
}

# Tool integrations: only source these if the tool is actually installed,
# so a fresh machine without rust/uv doesn't throw "no such file" errors.
#[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
