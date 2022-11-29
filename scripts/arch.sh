#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return

  sudo pacman -Syuq --noconfirm
  sudo -Sq --noconfirm yay binutils fakeroot curl wget clang
  checkpoint platform-setup
}

install-language-python() {
  cp "$HERE/.pylintrc" "$HOME"
  sudo pacman -Sq --noconfirm python ipython
  if ! hascmd pyright; then
    dc-install-nvm
    yarn global add -s pyright
  fi
  pushd ~/.local/bin >/dev/null
  test -e isort || "$HERE/scripts/make_standalone.py" isort
  test -e black || "$HERE/scripts/make_standalone.py" black
  test -e autoimport || "$HERE/scripts/make_standalone.py" autoimport
  popd >/dev/null
}

# shellcheck disable=SC2034
INSTALL_LANGUAGE_MISC_DOC="Random small languages like json & yaml"
install-language-misc() {
  sudo pacman -Syq --noconfirm pandoc yamllint shfmt
  install-misc-languages
}

install-language-lua() {
  yay -S --noconfirm luacheck
  sudo pacman -Syq --noconfirm ninja
  install-lua-utils
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  sudo pacman -Syq --noconfirm \
    glances \
    gnu-netcat \
    htop \
    inotify-tools \
    iotop \
    jq \
    lsof \
    mercurial \
    openssh \
    ripgrep \
    rsync \
    shellcheck \
    tmux \
    tree \
    unzip \
    wmctrl \
    xsel

  yay -S --noconfirm direnv
}

# shellcheck disable=SC2034
DC_INSTALL_NEOVIM_DOC="<3"
dc-install-neovim() {
  install-language-python
  if ! hascmd nvim; then
    if confirm "From github appimage?" y; then
      local version
      "$HERE/scripts/install_neovim.sh" --list
      version=$(prompt "Version?" stable)
      "$HERE/scripts/install_neovim.sh" "$version"
    else
      sudo pacman -Syq --noconfirm neovim
    fi
  fi
  post-install-neovim
}

# shellcheck disable=SC2034
DC_INSTALL_DOCKER_DOC="Docker and docker-compose"
dc-install-docker() {
  if ! hascmd docker; then
    rsync -lrp .docker "$HOME"
    sudo pacman -Syq --noconfirm docker
    confirm "Allow $USER to use docker without sudo?" y && sudo usermod -a -G docker "$USER"
  fi
  hascmd docker-compose || sudo pacman -Syq --noconfirm docker-compose
  setup-docker
}

# shellcheck disable=SC2034
DC_INSTALL_UFW_DOC="Uncomplicated FireWall with default config"
dc-install-ufw() {
  hascmd ufw && return
  sudo pacman -Syq --noconfirm ufw
  setup-ufw
}

dc-install-watchexec() {
  hascmd watchexec && return
  pacman -Syq --noconfirm watchexec
}

# shellcheck disable=SC2034
DOTCMD_DESKTOP_DOC="Install config and settings for desktop environment"
# shellcheck disable=SC2120
dotcmd-desktop() {
  if [ "$1" == "-h" ]; then
    echo "$DOTCMD_DESKTOP_DOC"
    return
  fi
  sudo pacman -Syq --noconfirm \
    blueman \
    bluez \
    dolphin-emu \
    ffmpeg \
    flatpak \
    kitty \
    libnotify \
    mupen64plus \
    rofi \
    steam \
    vlc \
    zenity
  setup-desktop-generic
  if [[ $XDG_CURRENT_DESKTOP =~ "GNOME" ]]; then
    sudo pacman -Syq --noconfirm dconf
    setup-gnome
  elif [[ $XDG_CURRENT_DESKTOP =~ "KDE" ]]; then
    setup-kde
  else
    echo "ERROR: Not sure what desktop environment this is."
  fi
}

# shellcheck disable=SC2034
DOTCMD_EVERYTHING_DOC="Set up everything I need for a new arch install"
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
