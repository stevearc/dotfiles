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
  brew install tmux karabiner-elements starship wget
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

install-language-python() {
  if ! hascmd pyright; then
    dc-install-yarn
    yarn global add pyright
  fi
}

install-language-misc() {
  dc-install-yarn
  yarn global add yaml-language-server
  yarn global add vscode-langservers-extracted
  yarn global add vim-language-server
}

install-language-js() {
  dc-install-yarn
  hascmd typescript-language-server || yarn global add typescript-language-server
}

install-language-lua() {
  hascmd luacheck || brew install luacheck
  hascmd stylua || brew install stylua

  # Install lua language server
  if [ ! -d ~/.local/share/nvim/language-servers/lua-language-server ]; then
    mkdir -p ~/.local/share/nvim/language-servers/lua-language-server
    pushd ~/.local/share/nvim/language-servers/lua-language-server
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | jq -r .name)
    wget "https://github.com/LuaLS/lua-language-server/releases/download/$latest_version/lua-language-server-$latest_version-darwin-arm64.tar.gz" ls.tar.gz
    tar -zxf ls.tar.gz
    rm -f ls.tar.gz
  fi
}

dc-install-yarn() {
  hascmd yarn || brew install yarn
}

install-language-bash() {
  if ! hascmd bash-language-server; then
    dc-install-yarn
    yarn global add bash-language-server
  fi
  hascmd shfmt || brew install shfmt
}

# shellcheck disable=SC2034
DC_INSTALL_NERD_FONT_DOC="Font with icons"
dc-install-nerd-font() {
  pushd /Library/Fonts/ >/dev/null
  fetch-nerd-font
  popd >/dev/null
}
