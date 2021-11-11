#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return

  sudo pamac upgrade -a --no-confirm
  sudo pamac install --no-confirm yay binutils fakeroot curl wget
  checkpoint platform-setup
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  has-checkpoint cli && return

  sudo pamac install --no-confirm tmux

  # TODO
  # sudo apt-get install -y -q \
  #   bsdmainutils \
  #   direnv \
  #   htop \
  #   glances \
  #   inotify-tools \
  #   iotop \
  #   jq \
  #   lsof \
  #   mercurial \
  #   netcat \
  #   openssh-client \
  #   rsync \
  #   ripgrep \
  #   shellcheck \
  #   tmux \
  #   tree \
  #   unzip \
  #   wmctrl \
  #   xsel

  checkpoint cli
}
