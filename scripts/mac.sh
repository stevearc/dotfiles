#!/bin/bash
set -e

platform-setup() {
  hascmd brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  has-checkpoint cli && return

  checkpoint cli
}

dc-install-tmux() {
  cd ~/Downloads
  curl -OL https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
  tar -xvf libevent-2.1.12-stable.tar.gz
  rm -f libevent-2.1.12-stable.tar.gz
  cd libevent-2.1.12-stable/
  ./configure
  make
  sudo make install
  cd ..
  rm -rf libevent-2.1.12-stable/

  curl -OL https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz
  tar -xvf tmux-3.1c.tar.gz
  rm -f tmux-3.1c.tar.gz
  cd tmux-3.1c/
  ./configure
  make
  sudo make install
  cd ..
  rm -rf tmux-3.1c/

  tmux -V
}
