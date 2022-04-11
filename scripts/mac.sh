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

  # Unfortunately these do not appear to work properly in Chrome, and in fact make me VERY ANGRY
  # defaults write -g NSUserKeyEquivalents -dict-add "Copy" -string '^c'
  # defaults write -g NSUserKeyEquivalents -dict-add "Cut" -string '^x'
  # defaults write -g NSUserKeyEquivalents -dict-add "Paste" -string '^v'
  # defaults write -g NSUserKeyEquivalents -dict-add "Paste and Match Style" -string '^$v'
  defaults write -g NSUserKeyEquivalents -dict-add "Select All" -string '^a'
  defaults write -g NSUserKeyEquivalents -dict-add "Undo" -string '^u'
  defaults write -g NSUserKeyEquivalents -dict-add "Redo" -string '^$u'
  defaults write -g NSUserKeyEquivalents -dict-add "Find..." -string '^f'

  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Close Tab" -string '^w'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "New Tab" -string '^t'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Reopen Closed Tab" -string '^$t'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "New Window" -string '^n'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "New Incognito Window" -string '^$n'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'Use Selection for Find' -string '^e'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'Developer Tools' -string '^Si'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'Reload This Page' -string '^r'
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'Open Location...' -string '^l'
  defaults write io.alacritty NSUserKeyEquivalents -dict-add "Paste" -string '^Sv'
  defaults write io.alacritty NSUserKeyEquivalents -dict-add "Copy" -string '^Sc'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Switch to Channel" -string '^k'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "All Unreads" -string '^$a'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Threads" -string '^$t'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "All DMs" -string '^$k'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Back" -string '^o'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Forward" -string '^i'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Reload" -string '^r'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Force Reload" -string '^$r'
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents -dict-add "Search" -string '^g'
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  brew install tmux karabiner-elements
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
  if [ ! -e UbuntuMono.zip ]; then
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/UbuntuMono.zip
    unzip UbuntuMono.zip
  fi
  rm -f UbuntuMono.zip
  popd >/dev/null
}
