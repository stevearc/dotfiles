#!/bin/bash

if [ -e /usr/share/fzf/completion.bash ]; then
  source /usr/share/fzf/completion.bash
fi
if [ -e /usr/share/fzf/key-bindings.bash ]; then
  source /usr/share/fzf/key-bindings.bash
fi

_fzf_complete_pacman() {
  _fzf_complete --multi --reverse --prompt="packages> " -- "$@" < <(pacman -Ss | paste -d" " - -)
}
_fzf_complete_pacman_post() {
  awk '{print $1}' | cut -f 2 -d /
}
complete -F _fzf_complete_pacman -o default -o bashdefault pacman
