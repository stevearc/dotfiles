# If not running interactively, don't do anything
[ -z "$PS1" ] && return
OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
fi

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

function git_branch {
    __cur_ref=`git log --abbrev-commit -1 --pretty="tformat:%h" 2> /dev/null`
    __git_branch=`git branch --no-color 2> /dev/null | grep -e ^* | sed -E s/^\\\*\ \(.*\)$/\\\1/ | sed -E s/^\\\\\(.*\\\\\)$/"$__cur_ref"/`
    echo `echo $__git_branch | sed -E s/\(.+\)/\[\\\1\]/`
}
function hg_branch {
  local branch=$(hg id -B -t 2> /dev/null)
  if [ -n "$branch" ]; then
    echo "[$branch]"
  fi
}
__exit_status() {
  local status="$?"
  local E=$(printf '\33')
  local red="${E}[31;1m"
  local reset="${E}[0;0m"
  [ "$status" == 0 ] && return
  if [ "$status" -gt 128 ]; then
    local signal="$(builtin kill -l $[${status} - 128] 2> /dev/null)"
    test "$signal" && signal=" ($signal)"
  fi
  echo "[${red}EXIT ${status}${signal}${reset}]"
  echo -e "\n"
}

__last_color="\[\033[00m\]"
__user="\[\033[01;32m\]\u$__last_color"
__host="\[\033[01;32m\]\h$__last_color"
__cur_location="\[\033[01;34m\]\w"
__git_branch_color="\[\033[0;32m\]"
__nvm_color="\[\033[0;37m\]"
__prompt_tail="\[\033[00m\]$"
function __nvm_version {
  command -v nvm > /dev/null || return
  local root=`git rev-parse --show-toplevel 2> /dev/null`
  [ -n "$root" ] || return
  [ -e "$root/package.json" ] || return
  echo "[`nvm current`]"
}
PS1='$(__exit_status)'"$__user@$__host$__cur_location:$__git_branch_color"'$(git_branch)$(hg_branch)'"$__nvm_color"'$(__nvm_version)'"$__prompt_tail$__last_color "
export PS4='+$0.$LINENO: '

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
elif [ $MAC ]; then
    alias ls='ls -G'
fi

# some more ls aliases
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -Alh'
alias inetstat='sudo netstat -pna|grep LISTEN|grep tcp'
alias pc='ps wwaux | grep'
alias ack='ag'
alias ivm='vim'
alias pdfcat='gs -q -sPAPERSIZE=letter -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=output.pdf'
alias tm='tmux -2'
if [ $MAC ]; then
  alias alert='reattach-to-user-namespace osascript -e "display notification \"$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]*[[:space:]]*//;s/[;&|][[:space:]]*alert$//'\'')\" with title \"$([ $? = 0 ] && echo Success || echo Error)\""'
  alias warn='[ $? != 0 ] && reattach-to-user-namespace osascript -e "display notification \"$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]*[[:space:]]*//;s/[;&|][[:space:]]*warn$//'\'')\" with title \"Error\""'
else
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
  alias warn='[ $? != 0 ] && notify-send --urgency=low -i "error" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*warn$//'\'')"'
fi
alias vp='xargs vim -p; reset'
alias fbm='CACA_DRIVER=ncurses mplayer -vo caca -really-quiet'
alias youtube-dl-mp3='youtube-dl -f bestaudio -x --audio-format mp3 --audio-quality 3'
alias orphans="ps -elf | head -1; ps -elf | awk '{if (\$5 == 1 && \$3 != \"root\") {print \$0}}' | head"
alias bp='bluepill'
alias bpe='bluepill enter'
alias mosh='mosh -6'
ash() {
    autossh -t "$@" 'tmux -2 attach || tmux -2 new'
}
export ash
sash() {
    autossh -t "$@" 'sudo tmux -2 attach || sudo tmux -2 new'
}
export sash


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

# Environment variables
export GOROOT=/usr/local/go
export GOPATH=~/go
export PATH=$HOME/bin:$GOROOT/bin:$GOPATH/bin:$PATH

# Default applications
export GIT_EDITOR=vim
export SVN_EDITOR=vim
export EDITOR=vim
export BROWSER=google-chrome-stable

command -v sourcedir > /dev/null 2>&1 || sourcedir() {
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

# NVM
sourcedir /usr/local/nvm/nvm.sh

# Autoenv
if command -v activate.sh > /dev/null; then
  source activate.sh
  autoenv_init
fi
