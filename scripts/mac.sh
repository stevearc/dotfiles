#!/bin/bash
set -e

platform-setup() {
  hascmd brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  brew install tmux
}

dc-install-neovim() {
  brew install neovim
  post-install-neovim
}
