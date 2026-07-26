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

# macOS's `vi` is already vim 9.x and reads this repo's vimrc, so this is mostly
# for tools that check $VISUAL first, and for machines where `vi` is a stripped
# down build or the fallback is nano.
export VISUAL=vim
export EDITOR="$VISUAL"

# Tool integrations: only source these if the tool is actually installed,
# so a fresh machine without rust/uv doesn't throw "no such file" errors.
#[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
