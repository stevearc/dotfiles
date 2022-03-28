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

# shellcheck disable=SC2034
DC_INSTALL_NERD_FONT_DOC="Font with icons"
dc-install-nerd-font() {
  pushd /Library/Fonts/ >/dev/null
  if [ ! -e UbuntuMono.zip ]; then
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/UbuntuMono.zip
    unzip UbuntuMono.zip
  fi
  rm -f UbuntuMono.zip
  popd >/dev/null
}
