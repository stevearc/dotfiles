#!/bin/bash
set -e

dc-install-fzf() {
  git clone --depth=1 https://github.com/junegunn/fzf.git ~/.local/share/nvim/site/pack/fzf/start/fzf
  git clone --depth=1 https://github.com/junegunn/fzf.vim.git ~/.local/share/nvim/site/pack/fzf.vim/start/fzf.vim
  nvim --headless -c 'call fzf#install()' +qall
}

dc-install-nvm() {
  if [ -e ~/.bash.d/nvm.sh ]; then
    source ~/.bash.d/nvm.sh || :
  fi
  hascmd nvm && nvm current && return
  local nvm_dir="${XDG_DATA_HOME-$HOME/.local/share}/nvm"
  if [ ! -e "$nvm_dir" ]; then
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
    pushd ~/.local/bin
    "$HERE/scripts/make_standalone.py" -s vint vim-vint
    popd
  fi
}

install-language-java() {
  [ -e ~/.local/share/jdtls ] && return
  pushd /tmp >/dev/null
  # This is kind of an old version, but the newer versions crash for me. Could have something to do with the version of java I'm using?
  wget https://download.eclipse.org/jdtls/milestones/0.70.0/jdt-language-server-0.70.0-202103051608.tar.gz
  mkdir -p ~/.local/share/jdtls
  tar -xf jdt-language-server-*.tar.gz -C ~/.local/share/jdtls
  rm -f jdt-language-server-*
  popd >/dev/null
}

install-language-rust() {
  if ! rustc --version >/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y -c rust-src
    source ~/.cargo/env
  fi
  if ! hascmd rust-analyzer; then
    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - >~/.local/bin/rust-analyzer
    chmod +x ~/.local/bin/rust-analyzer
  fi
  rustup component add rust-src
  if [ ! -e ~/.bash.d/rust.sh ]; then
    echo 'source ~/.cargo/env' >~/.bash.d/rust.sh
    echo 'export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"' >>~/.bash.d/rust.sh
  fi
}

install-language-zig() {
  local ZIG_VERSION=0.10.0
  if ! hascmd zig; then
    local dirname="zig-linux-x86_64-${ZIG_VERSION}"
    local tarball="zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
    local url="https://ziglang.org/download/${ZIG_VERSION}/$tarball"
    pushd /tmp >/dev/null
    curl -L "$url" -o "$tarball"
    tar -xf "$tarball"
    rm -rf "$HOME/.local/share/zig-linux-x86_64-${ZIG_VERSION}"
    mv "$dirname" ~/.local/share
    ln -sf "$HOME/.local/share/${dirname}/zig" "$HOME/.local/bin/zig"
    popd >/dev/null
  fi
  if ! hascmd zig-nightly; then
    local tarball="zig-linux-x86_64-nightly.tar.xz"
    local url
    url="$(curl -s https://ziglang.org/download/index.json | jq -r '.master["x86_64-linux"].tarball')"
    pushd /tmp >/dev/null
    curl -L "$url" -o "$tarball"
    rm -rf ~/.local/share/zig-nightly
    mkdir -p ~/.local/share/zig-nightly
    tar -xf "$tarball" --strip-components=1 -C ~/.local/share/zig-nightly
    ln -sf "$HOME/.local/share/zig-nightly/zig" "$HOME/.local/bin/zig-nightly"
    popd >/dev/null
  fi
  if ! hascmd zls; then
    if ! hascmd zstd; then
      if hascmd apt; then
        sudo apt install -yq zstd
      elif hascmd pacman; then
        sudo pacman -Syq --noconfirm zstd
      else
        echo "TODO need to install zstd"
      fi
    fi
    rm -rf "$HOME/.local/share/nvim/language-servers/zls"
    mkdir -p ~/.local/share/nvim/language-servers/zls
    pushd ~/.local/share/nvim/language-servers/zls >/dev/null
    curl -L https://github.com/zigtools/zls/releases/latest/download/x86_64-linux.tar.zst | tar --zstd -x --strip-components=1 -C .
    chmod +x "$HOME/.local/share/nvim/language-servers/zls/zls"
    ln -sf "$HOME/.local/share/nvim/language-servers/zls/zls" "$HOME/.local/bin/zls"
    popd >/dev/null
  fi
}

install-language-go() {
  if [ ! -e ~/.local/share/go ]; then
    pushd /tmp
    local pkg="go1.18.linux-amd64.tar.gz"
    if [ ! -e "$pkg" ]; then
      wget -O "$pkg" "https://golang.org/dl/$pkg"
    fi
    sudo tar -C ~/.local/share -xzf $pkg
    rm -f $pkg
    popd
  fi

  PATH="$HOME/.local/share/go/bin:$PATH"
  export GOPATH="$HOME/go"
  hascmd gopls || go install golang.org/x/tools/gopls@latest
  hascmd goimports || go install golang.org/x/tools/cmd/goimports@latest
  hascmd dlv || go install github.com/go-delve/delve/cmd/dlv@latest
}

install-language-js() {
  dc-install-nvm
  yarn global add -s flow-bin typescript-language-server
}

# shellcheck disable=SC2034
INSTALL_LANGUAGE_COMMON_DOC="Languages that I commonly use"
install-language-common() {
  install-language-python
  install-language-js
  install-language-go
  install-language-rust
  install-language-lua
  install-language-vim
  install-language-misc
}

install-arduino() {
  if ! hascmd arduino-cli; then
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=~/.local/bin sh
  fi

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

install-lua-utils() {
  hascmd cargo || cargo install stylua@0.15.2 --features lua52

  # Install lua language server
  mkdir -p ~/.local/share/nvim/language-servers/
  pushd ~/.local/share/nvim/language-servers/
  if [ ! -d lua-language-server ]; then
    git clone https://github.com/LuaLS/lua-language-server
    cd lua-language-server
    git fetch --tags
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | jq -r .name)
    git checkout "$latest_version"
    git submodule update --init --recursive
    cd 3rd/luamake
    ninja -f compile/ninja/linux.ninja
    cd ../..
    ./3rd/luamake/luamake rebuild
  fi
  popd
}

install-misc-languages() {
  dc-install-nvm
  yarn global add -s bash-language-server vscode-langservers-extracted yaml-language-server
}

setup-ufw() {
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow from 127.0.0.1
  if confirm "Allow ssh connections?" y; then
    sudo ufw allow 22/tcp
  fi
  if confirm "Allow steam connections?" y; then
    sudo ufw allow 27031/udp
    sudo ufw allow 27036/udp
    sudo ufw allow 27036/tcp
    sudo ufw allow 27037/tcp
  fi
  sudo ufw enable
}

setup-qtile() {
  if [ ! -e ~/.envs/qtile ]; then
    mkdir -p ~/.envs/qtile
    python -m venv ~/.envs/qtile
    ~/.envs/qtile/bin/pip install --upgrade pip wheel
    ~/.envs/qtile/bin/pip install --no-cache xcffib
    ~/.envs/qtile/bin/pip install --no-cache qtile iwlib dbus-next cairocffi python-mpd2
  fi
  if ! hascmd xidlehook; then
    install-language-rust
    cargo install xidlehook --bins
  fi
  sudo ln -sfT ~/.envs/qtile/bin/qtile /usr/bin/qtile
  sudo cp "$HERE/static/qtile.desktop" /usr/share/xsessions/
  sudo cp "$HERE/static/qtile-wayland.desktop" /usr/share/xsessions/
}

setup-docker() {
  mkdir -p ~/.docker-images
  if ! grep -q "^data-root" /etc/docker/daemon.json; then
    if [ ! -e /etc/docker/daemon.json ]; then
      sudo mkdir -p /etc/docker
      echo "{}" | sudo tee /etc/docker/daemon.json >/dev/null
    fi
    cat /etc/docker/daemon.json | jq '."data-root" = "'"$HOME"'/.docker-images"' >/tmp/docker-daemon.json
    sudo mv /tmp/docker-daemon.json /etc/docker/daemon.json
    sudo systemctl stop docker
    sleep 1
    sudo systemctl start docker
  fi
  if ! hascmd bluepill; then
    pushd ~/.local/bin
    curl -o install.py https://raw.githubusercontent.com/stevearc/bluepill/master/bin/install.py \
      && python install.py \
      && rm -f install.py
    popd
  fi
}
