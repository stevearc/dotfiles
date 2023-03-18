#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return
  sudo apt-get update -qq
  hascmd wget || sudo apt-get install -yq wget
  hascmd curl || sudo apt-get install -yq curl
  # TODO do I still need these? What for?
  # sudo apt-get install -y -q \
  #   python3-pycurl \
  #   software-properties-common
  checkpoint platform-setup
}

install-language-python() {
  cp "$HERE/.pylintrc" "$HOME"
  sudo apt-get install -yq \
    python3 \
    python-is-python3 \
    python3-distutils \
    python3-venv \
    python3-dev \
    python3-pip
  # ipython3 \
  # python3-restructuredtext-lint
  if [ "$1" != "--bare" ]; then
    if ! hascmd pyright; then
      dc-install-nvm
      yarn global add -s pyright
    fi
    pushd ~/.local/bin
    hascmd isort || "$HERE/scripts/make_standalone.py" isort
    hascmd black || "$HERE/scripts/make_standalone.py" black
    hascmd autoimport || "$HERE/scripts/make_standalone.py" autoimport
    popd
  fi
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
INSTALL_LANGUAGE_MISC_DOC="Random small languages like json & yaml"
install-language-misc() {
  sudo apt-get install -yq pandoc yamllint
  install-misc-languages
}

install-language-bash() {
  if ! hascmd bash-language-server; then
    dc-install-nvm
    yarn global add bash-language-server
  fi
  if ! hascmd shfmt; then
    install-language-go
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
  fi
}

install-language-lua() {
  sudo apt-get install -qy lua-check ninja-build
  install-lua-utils
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
  if ! hascmd docker-compose; then
    local latest
    latest=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .name)
    curl -L "https://github.com/docker/compose/releases/download/${latest}/docker-compose-$(uname -s)-$(uname -m)" -o ~/.local/bin/docker-compose
    chmod +x ~/.local/bin/docker-compose
    curl -L "https://raw.githubusercontent.com/docker/compose/${latest}/contrib/completion/bash/docker-compose" -o ~/.bash.d/docker-compose
  fi
  setup-docker
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
  install-language-python --bare
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

  post-install-neovim
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  sudo apt-get install -y -q \
    bsdmainutils \
    direnv \
    htop \
    inotify-tools \
    iotop \
    jq \
    lsof \
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
}

# shellcheck disable=SC2034
DC_INSTALL_QTILE_DOC="Qtile WM and friends"
dc-install-qtile() {
  sudo apt install -yq \
    arandr \
    compton \
    i3lock \
    inputplug \
    libiw-dev \
    libpangocairo-1.0-0 \
    libxcb-screensaver0-dev \
    pm-utils \
    python-dbus \
    python-gobject \
    python3-xcffib \
    rofi
  setup-qtile
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
    blueman \
    console-data \
    dunst \
    ffmpeg \
    flatpak \
    geoclue-2.0 \
    gparted \
    libnotify-bin \
    mplayer \
    ncmpcpp \
    redshift \
    vlc \
    xbindkeys \
    zenity
  if ! hascmd alacritty; then
    install-language-rust
    sudo apt install -yq libxcb-shape0-dev libxcb-xfixes0-dev libxcb-render0-dev
    cargo install alacritty
  fi

  if ! grep -q "GRUB_TIMEOUT=4" /etc/default/grub; then
    sudo sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=4/' /etc/default/grub
    sudo update-grub
  fi

  sudo cp static/reloadaudio.sh /usr/bin/

  setup-desktop-generic
  if [ ! -e ~/.themes/Layan ]; then
    pushd /tmp >/dev/null
    git clone --depth=1 https://github.com/vinceliuice/Layan-gtk-theme.git
    cd Layan-gtk-theme
    ./install.sh
    popd >/dev/null
  fi
  if [ ! -e ~/.local/share/icons/Tela ]; then
    pushd /tmp >/dev/null
    git clone --depth=1 https://github.com/vinceliuice/Tela-icon-theme.git
    cd Tela-icon-theme
    ./install.sh
    popd >/dev/null
  fi
  if ! snap list | grep layan-themes >/dev/null; then
    sudo snap install layan-themes
  fi
  if ! snap list | grep tela-icons >/dev/null; then
    sudo snap install tela-icons
  fi
  for i in $(snap connections | grep gtk-common-themes:gtk-3-themes | awk '{print $2}'); do sudo snap connect $i layan-themes:gtk-3-themes; done
  for i in $(snap connections | grep icon-themes | awk '{print $2}'); do sudo snap connect $i tela-icons:icon-themes; done
  if [[ $XDG_CURRENT_DESKTOP =~ "GNOME" ]]; then
    sudo apt install -yq dconf-cli
    setup-gnome
  elif [[ $XDG_CURRENT_DESKTOP =~ "KDE" ]]; then
    sudo apt install -yq plasma-nm
    setup-kde
  else
    echo "ERROR: Not sure what desktop environment this is."
  fi
}

dc-install-watchexec() {
  hascmd watchexec && return
  install-language-rust
  cargo install watchexec-cli
}

dc-install-rclone() {
  hascmd rclone && return
  local rclone_zip="rclone-current-linux-amd64.zip"
  local download_link="https://downloads.rclone.org/${rclone_zip}"
  pushd /tmp
  curl -OfsS "$download_link"
  local unzip_dir="tmp_unzip_dir_for_rclone"
  unzip -a "$rclone_zip" -d "$unzip_dir"
  cd $unzip_dir/*
  cp rclone ~/.local/bin/rclone
  chmod 755 ~/.local/bin/rclone
  mkdir -p ~/.local/share/man/man1
  cp rclone.1 ~/.local/share/man/man1/
  mandb || :
  popd
  post-install-rclone
}
