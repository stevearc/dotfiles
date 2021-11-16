#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return

  sudo pamac upgrade -a --no-confirm
  sudo pamac install --no-confirm yay binutils fakeroot curl wget clang
  checkpoint platform-setup
}

install-language-python() {
  cp "$HERE/.pylintrc" "$HOME"
  sudo pamac install --no-confirm python ipython
  if ! hascmd pyright; then
    dc-install-nvm
    yarn global add -s pyright
  fi
}

# shellcheck disable=SC2034
INSTALL_LANGUAGE_MISC_DOC="Random small languages like json & yaml"
install-language-misc() {
  sudo pamac install --no-confirm pandoc yamllint shfmt
  install-misc-languages
}

install-language-lua() {
  yay -S --noconfirm luacheck
  sudo pamac install --no-confirm ninja
  install-lua-utils
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  has-checkpoint cli && return

  sudo pamac install --no-confirm \
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

  checkpoint cli
}

# shellcheck disable=SC2034
DC_INSTALL_NEOVIM_DOC="<3"
dc-install-neovim() {
  install-language-python
  sudo pamac install --no-confirm neovim
  post-install-neovim
}

# shellcheck disable=SC2034
DC_INSTALL_AWESOME_DOC="Awesome WM and friends"
dc-install-awesome() {
  sudo pamac install --no-confirm awesome dmenu network-manager-applet
}

# shellcheck disable=SC2034
DC_INSTALL_DOCKER_DOC="Docker and docker-compose"
dc-install-docker() {
  if ! hascmd docker; then
    rsync -lrp .docker "$HOME"
    sudo pamac install --no-confirm docker
    confirm "Allow $USER to use docker without sudo?" y && sudo usermod -a -G docker "$USER"
  fi
  hascmd docker-compose || sudo pamac install --no-confirm docker-compose
  setup-docker
}

# shellcheck disable=SC2034
DC_INSTALL_UFW_DOC="Uncomplicated FireWall with default config"
dc-install-ufw() {
  hascmd ufw && return
  sudo pamac install --no-confirm ufw
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
  sudo pamac install --no-confirm \
    alacritty \
    discord \
    dolphin-emu \
    ffmpeg \
    mupen64plus \
    ncmpcpp \
    steam-manjaro \
    vlc
  yay -S --noconfirm google-chrome mopidy-spotify mopidy-mpd
  if ! hascmd youtube-dl; then
    pushd ~/bin >/dev/null
    wget -O youtube-dl https://yt-dl.org/latest/youtube-dl
    chmod +x youtube-dl
    popd >/dev/null
  fi
  setup-wallpaper
  if [[ $XDG_CURRENT_DESKTOP =~ "GNOME" ]]; then
    sudo pamac install --no-confirm dconf
    setup-gnome
  elif [[ $XDG_CURRENT_DESKTOP =~ "KDE" ]]; then
    sudo pamac install --no-confirm tela-icon-theme kvantum-qt5
    yay -S --noconfirm layan-gtk-theme-git layan-cursor-theme-git layan-kde-git kvantum-theme-layan-git
    setup-kde
  else
    echo "ERROR: Not sure what desktop environment this is."
  fi
}

# shellcheck disable=SC2034
DOTCMD_EVERYTHING_DOC="Set up everything I need for a new manjaro install"
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
