#!/bin/bash
set -e
declare -r DESKTOP_CONFIGS="
  alacritty
  karabiner
  kitty
  yamllint
"

platform-setup() {
  hascmd brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  keyboard-shortcuts
}

keyboard-shortcuts() {
  # @: Command
  # $: Shift
  # ~: Alt
  # ^: Ctrl

  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Reopen Closed Tab" -string '^$t'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "New Window" -string '^n'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "New Incognito Window" -string '^$n'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'Developer Tools' -string '^Si'
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  brew install tmux karabiner-elements starship
  # Also needed to download https://share.esdf.io/uKVV63N0hA/ (tmux.terminfo)
  # and run tic -x tmux.terminfo
  setup-configs
}

setup-configs() {
  for conf in $DESKTOP_CONFIGS; do
    local src="$HERE/.config/$conf"
    local dest="${XDG_CONFIG_HOME-$HOME/.config}/$conf"
    if [ -e "$src" ]; then
      mirror "$src" "$dest" 1
    fi
  done
  mirror "$HERE/.config/hammerspoon" "$HOME/.hammerspoon" 1
}

dc-install-neovim() {
  brew install neovim
  post-install-neovim
}

# shellcheck disable=SC2034
DC_INSTALL_NERD_FONT_DOC="Font with icons"
dc-install-nerd-font() {
  pushd /Library/Fonts/ >/dev/null
  fetch-nerd-font
  popd >/dev/null
}
