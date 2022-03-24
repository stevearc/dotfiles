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

alias ll='ls -lh'
alias la='ls -A'
alias lla='ls -Alh'
alias inetstat='sudo netstat -pna|grep LISTEN|grep tcp'
alias pc='ps wwaux | grep'
alias ack='ag'
alias gg='git grep -I'
alias pdfcat='gs -q -sPAPERSIZE=letter -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=output.pdf'
alias dua='du -had 1 | sort -rh'
alias tm='tmux'
alias dfh='df -h | grep -v tmpfs | grep -v snap'
if [ $MAC ]; then
  alias alert='notify -c $? "$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]*[[:space:]]*//;s/[;&|][[:space:]]*alert$//'\'')"'
  alias warn='[ $? != 0 ] && notify -u critical "$(history|tail -n1|sed -e '\''s/^[[:space:]]*[0-9]*[[:space:]]*//;s/[;&|][[:space:]]*warn$//'\'')"'
else
  alias alert='notify -c $? "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
  alias warn='[ $? != 0 ] && notify -u critical "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*warn$//'\'')"'
fi
alias fbm='CACA_DRIVER=ncurses mplayer -vo caca -really-quiet'
alias youtube-dl-mp3='youtube-dl -f bestaudio -x --audio-format mp3 --audio-quality 3'
alias orphans="ps -elf | head -1; ps -elf | awk '{if (\$5 == 1 && \$3 != \"root\") {print \$0}}' | head"
alias bp='bluepill'
alias bpe='bluepill enter'
alias sct='systemctl'
alias scu='systemctl --user'
zlibd() (printf "\x1f\x8b\x08\x00\x00\x00\x00\x00" | cat - $@ | gzip -dc)
alias mosh='mosh -6'
ash() {
  autossh -t "$@" 'tmux -2 attach || tmux new'
}
sash() {
  autossh -t "$@" 'sudo tmux -2 attach || sudo tmux new'
}
if command -v nvim >/dev/null; then
  if [ -n "$INSIDE_NVIM" ] && command -v nvr >/dev/null; then
    alias vim="nvr -cc 'tabnew | let w:is_remote = v:true'"
  else
    alias vim="nvim"
  fi
  alias vi="vim"
fi
if command -v rg >/dev/null; then
  alias ag='rg'
  alias ack='rg'
elif command -v ag >/dev/null; then
  alias ack='ag'
fi
and() {
  [ $? = 0 ] && "$@"
}
or() {
  [ $? != 0 ] && "$@"
}
alias hr='history -c; history -r'
__vimm() {
  if git rev-parse --git-dir 2>/dev/null; then
    vim $(git sm @)
  elif hg id 2>/dev/null; then
    vim $(hg mod)
  fi
}
alias vimm='__vimm'

scsv() {
  local tmpfile
  tmpfile="$(mktemp).sc"
  local tablefile
  tablefile="$(mktemp).txt"
  local macro
  macro="$(mktemp).sc"
  echo -e "set tblstyle = 0\ntbl \"$tablefile\"\nquit" >"$macro"
  cat "$1" | psc -k -d, >"$tmpfile"
  sc "$tmpfile"
  sc "$tmpfile" "$macro"
  cat "$tablefile" | tr -d ' ' | tr ':' ',' >"$1"
  rm -f "$tmpfile" "$tablefile" "$macro"
}

plugvim() {
  local repo="${1?Usage: plugvim [REPO]}"
  local name="${1##*/}"
  git clone "$repo" "$HOME/.local/share/nvim/site/pack/tmp/start/$name"
}
