OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
fi

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
alias gg='git grep -I'
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
alias pip-install-pyls='pip install python-language-server[rope] pyls-mypy pyls-black pyls-isort rope mypy black isort'
alias mosh='mosh -6'
ash() {
    autossh -t "$@" 'tmux -2 attach || tmux -2 new'
}
export ash
sash() {
    autossh -t "$@" 'sudo tmux -2 attach || sudo tmux -2 new'
}
export sash
if command -v nvim > /dev/null; then
  alias vim='nvim'
  alias vi='nvim'
else
  alias nvim='vim'
  alias vi='vim'
fi
and() {
  [ $? = 0 ] && "$@"
}
export and
or() {
  [ $? != 0 ] && "$@"
}
export or
alias hr='history -c; history -r'
vimm() {
  if git rev-parse --git-dir 2> /dev/null; then
    vim -p $(git sm @)
  elif hg id 2> /dev/null; then
    vim -p $(hg mod)
  fi
}
export vimm

scsv() {
  local tmpfile
  tmpfile="$(mktemp).sc"
  local tablefile
  tablefile="$(mktemp).txt"
  local macro
  macro="$(mktemp).sc"
  echo -e "set tblstyle = 0\ntbl \"$tablefile\"\nquit" > "$macro"
  cat "$1" | psc -k -d, > "$tmpfile"
  sc "$tmpfile"
  sc "$tmpfile" "$macro"
  cat "$tablefile" | tr -d ' ' | tr ':' ',' > "$1"
  rm -f "$tmpfile" "$tablefile" "$macro"
}
export scsv
