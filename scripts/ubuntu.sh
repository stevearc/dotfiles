#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return
  sudo apt-get update -qq
  sudo apt-get install -y -q \
    python-pycurl \
    software-properties-common \
    wget \
    curl
  checkpoint platform-setup
}

install-language-python() {
  cp "$HERE/.pylintrc" "$HOME"
  sudo apt-get install -y -q \
    python3 \
    python-is-python3 \
    python3-distutils \
    python3-venv
  if ! hascmd pyright; then
    dc-install-nvm
    yarn global add -s pyright
  fi
  sudo apt-get install -y -q \
    python3-dev \
    python3-pip \
    ipython3 \
    python3-restructuredtext-lint
}

install-language-arduino() {
  install-arduino
  groups | grep dialout || sudo usermod -a -G dialout "$USER"
  if [ ! -e /etc/udev/rules.d/99-USBtiny.rules ]; then
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1781", ATTR{idProduct}=="0c9f", GROUP="dialout", MODE="0666"' | sudo tee /etc/udev/rules.d/99-USBtiny.rules
    sudo service udev restart
    sudo udevadm control --reload-rules
    sudo udevadm trigger
  fi
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

# shellcheck disable=SC2034
INSTALL_LANGUAGE_MISC_DOC="Random small languages like json & yaml"
install-language-misc() {
  sudo apt-get install -yq pandoc yamllint
  dc-install-nvm
  yarn global add -s bash-language-server vscode-langservers-extracted yaml-language-server
  install-language-go
  if ! hascmd shfmt; then
    GO111MODULE=on go get mvdan.cc/sh/v3/cmd/shfmt
  fi
}

install-language-lua() {
  sudo apt-get install -qy lua-check
  if hascmd cargo; then
    cargo install stylua
  fi

  # Install lua language server
  mkdir -p ~/.local/share/nvim/language-servers/
  pushd ~/.local/share/nvim/language-servers/
  if [ ! -d lua-language-server ]; then
    sudo apt install -qy ninja-build
    git clone https://github.com/sumneko/lua-language-server
    cd lua-language-server
    git submodule update --init --recursive
    cd 3rd/luamake
    ninja -f compile/ninja/linux.ninja
    cd ../..
    ./3rd/luamake/luamake rebuild
  fi
  popd
}

install-language-sc() {
  local SC_VERSION="Version-3.11.2"
  sudo adduser "$USER" audio
  if hascmd ufw; then
    # Allow local network traffic to supercollider
    sudo ufw allow proto udp from 192.168.0.0/16 to any port 57120
    # Allow local network traffic for TouchOSC editor
    sudo ufw allow from 192.168.0.0/16 to any port 6666
  fi
  if ! hascmd scide; then
    sudo apt-get install -yq jackd2 build-essential cmake g++ libsndfile1-dev libjack-jackd2-dev libfftw3-dev libxt-dev libavahi-client-dev libasound2-dev libicu-dev libreadline6-dev libudev-dev pkg-config libncurses5-dev qt5-default qt5-qmake qttools5-dev qttools5-dev-tools qtdeclarative5-dev qtwebengine5-dev libqt5svg5-dev libqt5websockets5-dev
    pushd /tmp
    if [ ! -e SuperCollider ]; then
      git clone --recurse-submodules https://github.com/SuperCollider/SuperCollider.git
    fi
    cd SuperCollider
    git checkout "$SC_VERSION"
    git submodule update --init --recursive
    mkdir -p build
    cd build
    cmake -DCMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu -DCMAKE_BUILD_TYPE=Release -DNATIVE=ON -DSC_EL=no ..
    make -j8
    sudo make install
    sudo ldconfig
    popd
  fi
  local extensions="/usr/local/share/SuperCollider/Extensions"
  if [ ! -e "$extensions/SC3plugins" ]; then
    pushd /tmp
    if [ ! -e sc3-plugins ]; then
      git clone --recursive https://github.com/supercollider/sc3-plugins.git
    fi
    mkdir -p sc3-plugins/build
    cd sc3-plugins/build
    cmake -DSC_PATH=/tmp/SuperCollider -DCMAKE_BUILD_TYPE=Release -DSUPERNOVA=ON ..
    sudo cmake --build . --config Release --target install
    popd
  fi
  mkdir -p ~/ws/music
  pushd ~/ws/music
  if hascmd rclone; then
    rclone sync -v drive:/Dropbox/samples/ ./samples
  fi
  if [ ! -e StevearcExperimentalQuark ]; then
    git clone --recursive git@github.com:stevearc/StevearcExperimentalQuark
  fi
  if [ ! -e Beats ]; then
    git clone --recursive git@github.com:stevearc/Beats
  fi
  if [ ! -e Looper ]; then
    git clone --recursive git@github.com:stevearc/Looper
  fi
  if [ ! -e Sampler ]; then
    git clone --recursive git@github.com:stevearc/Sampler
  fi
  if [ ! -e Timing ]; then
    git clone --recursive git@github.com:stevearc/Timing
  fi
  cd ..
  if [ ! -e SCLOrkSynths ]; then
    git clone --recursive git@github.com:stevearc/SCLOrkSynths
  fi
  popd
  cat >/tmp/scsetup.scd <<EOF
if (Quarks.isInstalled("Bjorklund").not) {
  Quarks.install("Bjorklund");
};
if (Quarks.isInstalled("SCLOrkSynths").not) {
  Quarks.install("$HOME/ws/SCLOrkSynths");
};
if (Quarks.isInstalled("Beats").not) {
  Quarks.install("$HOME/ws/music/Beats");
};
if (Quarks.isInstalled("Looper").not) {
  Quarks.install("$HOME/ws/music/Looper");
};
if (Quarks.isInstalled("Sampler").not) {
  Quarks.install("$HOME/ws/music/Sampler");
};
if (Quarks.isInstalled("Timing").not) {
  Quarks.install("$HOME/ws/music/Timing");
};
if (Quarks.isInstalled("StevearcExperimentalQuark").not) {
  Quarks.install("$HOME/ws/music/StevearcExperimentalQuark");
};
0.exit;
EOF
  sclang /tmp/scsetup.scd
  nvim --headless +"call scnvim#install()" +qall >/dev/null
}

# shellcheck disable=SC2034
DOTCMD_EVERYTHING_DOC="Set up everything I need for a new ubuntu install"
dotcmd-everything() {
  if [ "$1" == "-h" ]; then
    echo "$DOTCMD_EVERYTHING_DOC"
    return
  fi

  dc-install-common
  dc-install-neovim
  dotcmd-dotfiles
  install-language-common
  dc-install-ufw
  dotcmd-desktop
  echo "Done"
}

# shellcheck disable=SC2034
DC_INSTALL_DOCKER_DOC="Docker and docker-compose"
dc-install-docker() {
  if ! hascmd docker; then
    rsync -lrp .docker "$HOME"
    sudo apt-get install -yq \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
    sudo apt-get update -qq
    sudo apt-get install -yq docker-ce
    confirm "Allow $USER to use docker without sudo?" y && sudo adduser "$USER" docker
  fi
  mkdir -p ~/.docker-images
  if ! grep -q "^data-root" /etc/docker/daemon.json; then
    cat /etc/docker/daemon.json | jq '."data-root" = "'"$HOME"'/.docker-images"' >/tmp/docker-daemon.json
    sudo mv /tmp/docker-daemon.json /etc/docker/daemon.json
    sudo service docker stop
    sleep 1
    sudo service docker start
  fi
  if ! hascmd bluepill; then
    pushd ~/bin
    curl -o install.py https://raw.githubusercontent.com/stevearc/bluepill/master/bin/install.py \
      && python install.py \
      && rm -f install.py
    popd
  fi
  if ! hascmd docker-compose; then
    local latest
    latest=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .name)
    curl -L "https://github.com/docker/compose/releases/download/${latest}/docker-compose-$(uname -s)-$(uname -m)" -o ~/bin/docker-compose
    chmod +x ~/bin/docker-compose
    curl -L "https://raw.githubusercontent.com/docker/compose/${latest}/contrib/completion/bash/docker-compose" -o ~/.bash.d/docker-compose
  fi
}

dc-install-dotnet() {
  if hascmd dotnet; then
    return
  fi
  # From https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
  pushd /tmp
  wget "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb

  sudo apt-get update
  sudo apt-get install -y apt-transport-https
  sudo apt-get update
  sudo apt-get install -y dotnet-sdk-3.1
  popd
}

# shellcheck disable=SC2034
DC_INSTALL_NEOVIM_DOC="<3"
dc-install-neovim() {
  install-language-python
  hascmd gcc || sudo apt install -y -q gcc
  if ! hascmd nvim; then
    if confirm "From github appimage?" y; then
      local version
      "$HERE/scripts/install_neovim.sh" --list
      version=$(prompt "Version?" stable)
      "$HERE/scripts/install_neovim.sh" "$version"
    elif confirm "From source?" n; then
      sudo apt-get install -y libtool autoconf automake cmake g++ gettext pkg-config \
        unzip python3 python3-dev python3-venv ruby-dev
      sudo apt-get install -y libtool-bin
      pushd /tmp
      test -d neovim || git clone https://github.com/neovim/neovim.git
      cd neovim
      make CMAKE_BUILD_TYPE=Release
      sudo make install
      popd
    else
      sudo apt-get install -y neovim
    fi
  fi

  # Let's just always do the things for neovim
  [ -d ~/.envs ] || mkdir ~/.envs
  [ -d ~/.envs/py3 ] || python3 -m venv ~/.envs/py3
  ~/.envs/py3/bin/pip install -q wheel
  ~/.envs/py3/bin/pip install -q pynvim

  if ! hascmd nvr; then
    mkdir -p ~/bin
    pushd ~/bin
    "$HERE/scripts/make_standalone.py" -s nvr neovim-remote
    popd
  fi
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  has-checkpoint cli && return
  sudo apt-get install -y -q \
    bsdmainutils \
    direnv \
    htop \
    glances \
    inotify-tools \
    iotop \
    jq \
    lsof \
    mercurial \
    netcat \
    openssh-client \
    rsync \
    ripgrep \
    shellcheck \
    tmux \
    tree \
    unzip \
    wmctrl \
    xsel

  checkpoint cli
}

# shellcheck disable=SC2034
DC_INSTALL_UFW_DOC="Uncomplicated FireWall with default config"
dc-install-ufw() {
  hascmd ufw && return
  sudo apt-get install -y -q ufw
  setup-ufw
}

# shellcheck disable=SC2034
DOTCMD_DESKTOP_DOC="Install config and settings for desktop environment"
# shellcheck disable=SC2120
dotcmd-desktop() {
  if [ "$1" == "-h" ]; then
    echo "$DOTCMD_DESKTOP_DOC"
    return
  fi
  dc-install-nerd-font

  # Enable multiverse
  sudo sed -i -e 's/# \(.* multiverse$\)/\1/' /etc/apt/sources.list
  sudo apt-get update -qq

  sudo apt-get install -q -y \
    gparted \
    ffmpeg \
    mplayer \
    vlc
  if ! hascmd youtube-dl; then
    pushd ~/bin >/dev/null
    wget -O youtube-dl https://yt-dl.org/latest/youtube-dl
    chmod +x youtube-dl
    popd >/dev/null
  fi

  if ! grep -q "GRUB_TIMEOUT=4" /etc/default/grub; then
    sudo sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=4/' /etc/default/grub
    sudo update-grub
  fi

  sudo cp static/reloadaudio.sh /usr/bin/

  if hascmd gsettings; then
    setup-gnome
  else
    echo "ERROR: Not sure what desktop environment this is."
    # setup-xfce
  fi
}
