#!/bin/bash
set -e

dc-install-nvm() {
  if [ -e ~/.bash.d/nvm.sh ]; then
    source ~/.bash.d/nvm.sh || :
  fi
  hascmd nvm && nvm current && return
  local nvm_dir
  nvm_dir=$(prompt "NVM install dir:" "${XDG_CONFIG_HOME-$HOME/.config}/nvm")
  if [ ! -d "$nvm_dir" ]; then
    mkdir -p "$nvm_dir"
    local latest
    latest=$(
      curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .name
    )
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$latest/install.sh" \
      | NVM_DIR="$nvm_dir" PROFILE=/dev/null bash
  fi
  source "$nvm_dir/nvm.sh"
  mkdir -p ~/.bash.d
  echo -e "source $nvm_dir/nvm.sh\nsource $nvm_dir/bash_completion" >~/.bash.d/nvm.sh
  local node_version
  node_version=$(nvm ls-remote | tail -n 1 | awk '{print $1}')
  node_version=$(prompt "Install node version:" "$node_version")
  nvm ls "$node_version" || nvm install --default "$node_version"
  nvm use default
  if ! hascmd yarn; then
    npm install -g yarn
  fi
}

install-language-vim() {
  dc-install-nvm
  yarn global add -s vim-language-server
  install-language-python
  if ! hascmd vint; then
    pushd ~/bin
    "$HERE/scripts/make_standalone.py" -s vint vim-vint
    popd
  fi
}

install-language-rust() {
  if ! rustc --version >/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
  fi
  if ! hascmd rust-analyzer; then
    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux -o ~/bin/rust-analyzer
    chmod +x ~/bin/rust-analyzer
  fi
  rustup component add rust-src
  if [ ! -e ~/.bash.d/rust.sh ]; then
    echo 'source ~/.cargo/env' >~/.bash.d/rust.sh
    echo 'export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"' >>~/.bash.d/rust.sh
  fi
}

install-language-go() {
  if [ ! -e /usr/local/go ]; then
    pushd /tmp
    local pkg="go1.15.6.linux-amd64.tar.gz"
    if [ ! -e "$pkg" ]; then
      wget -O "$pkg" "https://golang.org/dl/$pkg"
    fi
    sudo tar -C /usr/local -xzf $pkg
    rm -f $pkg
    popd
  fi

  PATH="/usr/local/go/bin:$PATH"
  export GOPATH="$HOME/go"
  if ! hascmd gopls; then
    GO111MODULE=on go get golang.org/x/tools/gopls
    GO111MODULE=on go clean -modcache
  fi
}

install-language-js() {
  dc-install-nvm
  yarn global add -s flow-bin typescript-language-server
}

install-arduino() {
  hascmd arduino && return

  local default_version
  default_version=$(curl https://github.com/arduino/Arduino/releases/latest | sed 's|^.*tag/\([^"]*\).*$|\1|')
  local version
  version=$(prompt "Arduino IDE version?" "$default_version")
  local install_dir
  install_dir=$(prompt "Arduino IDE install dir?" /usr/local/share)
  local zipfile="arduino-${version}-linux64.tar.xz"
  pushd /tmp >/dev/null
  wget -O "$zipfile" "http://downloads.arduino.cc/$zipfile"
  tar -Jxf "$zipfile"
  sudo mv "arduino-${version}" "$install_dir"
  sudo ln -sfT "arduino-${version}" "$install_dir/arduino"
  sudo ln -sf "$install_dir/arduino/arduino" /usr/local/bin/arduino
  popd >/dev/null
}

setup-ufw() {
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  if confirm "Allow ssh connections?" y; then
    sudo ufw allow 22/tcp
    sudo apt-get install -y -q openssh-server
  fi
  if confirm "Allow steam connections?" y; then
    sudo ufw allow 27031/udp
    sudo ufw allow 27036/udp
    sudo ufw allow 27036/tcp
    sudo ufw allow 27037/tcp
  fi
  sudo ufw enable
}
