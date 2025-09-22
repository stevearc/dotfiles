#!/bin/bash
PROFILE_STARTUP=

# If not running interactively, don't do anything
[ -z "$PS1" ] && return
OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
fi

if [ -n "$PROFILE_STARTUP" ]; then
  if [ $MAC ]; then
    PS4='+ $(gdate "+%s.%N")\011 '
  else
    PS4='+ $(date "+%s.%N")\011 '
  fi
  prof_file=/tmp/bashstart.$$.log
  exec 3>&2 2>$prof_file
  set -x
fi

# Disable XON/XOFF flow control because it collides with C-s
[[ $- == *i* ]] && stty -ixon

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000

# After each command, append to the history file
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Environment variables
if [ $MAC ]; then
  export GOROOT="/opt/homebrew/opt/go/libexec"
  export PATH="$GOROOT/bin:$PATH"
elif [ -d "$HOME/.local/share/go" ]; then
  export GOROOT=$HOME/.local/share/go
  export PATH="$GOROOT/bin:$PATH"
fi
export GOPATH=~/go
export PATH="$HOME/.local/bin:$GOPATH/bin:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

if [ -e "$HOME/.yarn/bin" ]; then
  export PATH="$PATH:$HOME/.yarn/bin"
fi
# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
fi
# For some reason on arch these completions are not sourced by default
if [ -d /usr/share/bash-completion/completions ]; then
  for c in /usr/share/bash-completion/completions/*; do
    source "$c" 2>/dev/null
  done
fi
if [ -f /opt/homebrew/etc/bash_completion ]; then
  . /opt/homebrew/etc/bash_completion
fi

if command -v nvim >/dev/null; then
  alias vim="nvim"
  alias vi="nvim"
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export GIT_EDITOR="$EDITOR"
export SVN_EDITOR="$EDITOR"

if command -v firefox >/dev/null; then
  export BROWSER=firefox
else
  export BROWSER=google-chrome-stable
fi

command -v sourcedir >/dev/null 2>&1 || sourcedir() {
  if [ -d "$1" ]; then
    for filename in $1/*.sh; do
      if [ -e "$filename" ]; then
        source "$filename"
      fi
    done
  elif [ -f "$1" ]; then
    source $1
  fi
}

sourcedir ~/.bash_env
sourcedir ~/.bash.d
sourcedir ~/.bash.completion

if [ -f ~/.yarn/bin ]; then
  export PATH="$HOME/.yarn/bin:$PATH"
fi

if command -v fzf >/dev/null; then
  eval "$(fzf --bash)"
fi

export PATH="/usr/local/sbin:$PATH"
export NVIM_LOG_FILE_PATH="$HOME/.nvimlog"
if command -v direnv >/dev/null; then
  eval "$(direnv hook bash)"
  show_virtual_env() {
    if [[ -n $VIRTUAL_ENV && -n $DIRENV_DIR ]]; then
      echo "($(basename $VIRTUAL_ENV)) "
    fi
  }
  export -f show_virtual_env
  PS1=$PS1'$(show_virtual_env)'
fi

if [ "$XDG_SESSION_TYPE" == "tty" ] && [ -z "$SSH_TTY" ]; then
  sudo loadkeys ~/.config/keystrings
fi

export DOCKER_GUI="--net=host --env=DISPLAY --volume=$HOME/.Xauthority:/root/.Xauthority:rw"

if command -v starship >/dev/null; then
  eval "$(starship init bash)"
else
  function git_branch {
    [ -n "$NO_SHOW_GIT_BRANCH" ] && return
    __cur_ref=$(git log --abbrev-commit -1 --decorate=short --pretty="tformat:%h{%D" 2>/dev/null | sed -e 's/{.*\(tag: [^ ,]*\).*$/}\1/' -e 's/{.*//' -e 's/ //' -e 's/}/ /' 2>/dev/null)
    __git_branch=$(git branch --no-color 2>/dev/null | grep -e ^* | sed -E s/^\\*\ \(.*\)$/\\1/ | sed -E s/^\\\(.*\\\)$/"$__cur_ref"/)
    echo $(echo $__git_branch | sed -E s/\(.+\)/\[\\1\]/)
  }
  function hg_branch {
    [ -n "$NO_SHOW_HG_BRANCH" ] && return
    local branch=$(hg id -B -t 2>/dev/null)
    if [ -n "$branch" ]; then
      echo "[$branch]"
    fi
  }

  __last_color="\[\033[00m\]"
  __user="\[\033[01;32m\]\u$__last_color"
  __host="\[\033[01;32m\]\h$__last_color"
  __cur_location="\[\033[01;34m\]\w"
  __git_branch_color="\[\033[0;32m\]"
  __nvm_color="\[\033[0;37m\]"
  __prompt_tail="\[\033[00m\]$"
  function __nvm_version {
    command -v nvm >/dev/null || return
    local root=$(git rev-parse --show-toplevel 2>/dev/null)
    [ -n "$root" ] || return
    [ -e "$root/package.json" ] || return
    echo "[$(nvm current)]"
  }
  function __timestamp {
    echo "$(date +%H:%M:%S) "
  }
  PS1='$(__timestamp)'"$__user@$__host$__cur_location:$__git_branch_color"'$(git_branch)$(hg_branch)'"$__nvm_color"'$(__nvm_version)'"$__prompt_tail$__last_color "
  if [ -n "$PROFILE_STARTUP" ]; then
    export PS4='+$0.$LINENO: '
  fi
fi

if [ -n "$PROFILE_STARTUP" ]; then
  set +x
  exec 2>&3 3>&-
  echo "Profile written to $prof_file"
fi
