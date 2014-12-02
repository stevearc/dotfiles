# If not running interactively, don't do anything
[ -z "$PS1" ] && return

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

__last_color="\[\033[00m\]"
__user="\[\033[01;32m\]\u$__last_color"
__host="\[\033[01;32m\]\h$__last_color"
__cur_location="\[\033[01;34m\]\w"
__git_branch_color="\[\033[0;32m\]"
__prompt_tail="\[\033[00m\]$"
PS1="$__user@$__host$__cur_location:$__git_branch_color"'$(git_branch)'"$__prompt_tail$__last_color "

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -Alh'
alias inetstat='sudo netstat -pna|grep LISTEN|grep tcp'
alias grep='grep --color=auto'
alias pc='ps wwaux | grep'
alias ack='ack-grep'
alias ivm='vim'
alias pdfcat='gs -q -sPAPERSIZE=letter -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=output.pdf'
alias tm='tmux -2'
alias ackc='ack --coffeescript'
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
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export GIT_EDITOR=vim
export SVN_EDITOR=vim

if [ -f ~/.bash_env ]; then
    . ~/.bash_env
fi
# Autoenv
. activate.sh
