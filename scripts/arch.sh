#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return

  sudo pacman -Syuq --noconfirm
  sudo pacman -Sq --noconfirm yay binutils fakeroot curl wget clang
  checkpoint platform-setup
}

install-language-python() {
  cp "$HERE/.pylintrc" "$HOME"
  sudo pacman -Sq --noconfirm python ipython
  if ! hascmd pyright; then
    dc-install-nvm
    yarn global add -s pyright
  fi
  mkdir -p ~/.local/bin
  pushd ~/.local/bin >/dev/null
  test -e isort || "$HERE/scripts/make_standalone.py" isort
  test -e black || "$HERE/scripts/make_standalone.py" black
  test -e autoimport || "$HERE/scripts/make_standalone.py" autoimport
  popd >/dev/null
}

# shellcheck disable=SC2034
INSTALL_LANGUAGE_MISC_DOC="Random small languages like json & yaml"
install-language-misc() {
  sudo pacman -Syq --noconfirm pandoc yamllint
  install-misc-languages
}

install-language-bash() {
  if ! hascmd bash-language-server; then
    dc-install-nvm
    yarn global add bash-language-server
  fi
  hascmd shfmt || sudo pacman -Syq --noconfirm shfmt
}

install-language-lua() {
  yay -S --noconfirm luacheck
  sudo pacman -Syq --noconfirm ninja
  install-lua-utils
}

DC_INSTALL_JELLYFIN_DOC="Jellyfin media server"
dc-install-jellyfin() {
  yay -S --noconfirm jellyfin-bin
  sudo systemctl start jellyfin.service
  sudo systemctl enable jellyfin.service
  xdg-open http://localhost:8096
  if hascmd ufw; then
    sudo ufw allow proto udp from 192.168.1.0/24 to any port 8096 comment 'jellyfin'
    sudo ufw allow proto tcp from 192.168.1.0/24 to any port 8096 comment 'jellyfin'
  fi
  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-port=8096/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=8096/tcp
  fi
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  sudo pacman -Syq --noconfirm \
    gnu-netcat \
    htop \
    inotify-tools \
    iotop \
    jq \
    lsof \
    openssh \
    ripgrep \
    rsync \
    starship \
    tmux \
    tree \
    unzip \
    wmctrl \
    xsel

  hascmd direnv || yay -S --noconfirm direnv
  hascmd shellcheck || yay -S --noconfirm shellcheck-bin
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
    bluedevil \
    blueman \
    bluez \
    dolphin-emu \
    ffmpeg \
    flatpak \
    gtk2 \
    kitty \
    libnotify \
    mupen64plus \
    steam \
    vlc \
    zenity
  yay -S --noconfirm tomb # gtk2 above is a dependency
  setup-desktop-generic
  if [[ $XDG_CURRENT_DESKTOP =~ "GNOME" ]]; then
    sudo pacman -Syq --noconfirm dconf
    setup-gnome
  elif [[ $XDG_CURRENT_DESKTOP =~ "KDE" ]]; then
    setup-kde
  elif [[ $XDG_CURRENT_DESKTOP =~ "XFCE" ]]; then
    setup-xfce
  else
    echo "ERROR: Not sure what desktop environment this is."
  fi
}

# shellcheck disable=SC2034
DOTCMD_PIBOX_DOC="Set up the raspberry pi"
dotcmd-pibox() {
  dc-install-common
  sudo pacman -Syq --noconfirm neovim
  post-install-neovim
  dotcmd-dotfiles
  setup-xfce
  dc-install-nerd-font
  sudo pacman -Syq --noconfirm \
    cronie \
    ffmpeg \
    flatpak \
    kitty \
    openssh \
    rclone \
    tigervnc \
    transmission-cli \
    vlc
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  dc-install-kitty
  dc-install-jellyfin
  hascmd mullvad || yay -S --noconfirm mullvad-vpn-bin
  if [ "$(mullvad status)" = "Disconnected" ]; then
    echo "Log in to Mullvad"
    mullvad account login
    mullvad auto-connect set on
    mullvad lan set allow
    mullvad relay set tunnel-protocol wireguard
    mullvad relay set location us lax
    echo "Go to https://mullvad.net/account/#/port-forwarding to configure port forwarding. Device is below"
    mullvad account get
  fi
  if [ -e ~/.config/mullvad_port ]; then
    mullvad_port="$(cat ~/.config/mullvad_port)"
  else
    read -r -p "What port was forwarded for Mullvad? " mullvad_port
    echo "$mullvad_port" > ~/.config/mullvad_port
  fi
  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
  sudo systemctl enable cronie.service
  sudo systemctl start cronie.service

  test -e /etc/cron.hourly/rsync_torrents || sudo cp "$HERE/static/rsync_torrents" /etc/cron.hourly/
  test -e /etc/cron.hourly/chown_jellyfin || sudo cp "$HERE/static/chown_jellyfin" /etc/cron.hourly/

  if hascmd firewall-cmd; then
    # Set the current zone to home
    sudo firewall-cmd --zone=home --change-interface=wlan0
    sudo firewall-cmd --zone=home --change-interface=end0
    sudo firewall-cmd --zone=home --change-interface=wlan0 --permanent
    sudo firewall-cmd --zone=home --change-interface=end0 --permanent
    # Open ports for ssh
    sudo firewall-cmd --zone=home --add-port=22/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=22/tcp
    # Transmission
    sudo firewall-cmd --zone=home --add-port=9091/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=9091/tcp
    if [ -n "$mullvad_port" ]; then
      sudo firewall-cmd --zone=home --add-port="${mullvad_port}/tcp"
      sudo firewall-cmd --permanent --zone=home --add-port="${mullvad_port}/tcp"
      sudo firewall-cmd --zone=public --add-port="${mullvad_port}/tcp"
      sudo firewall-cmd --permanent --zone=public --add-port="${mullvad_port}/tcp"
    fi
    # VNC
    sudo firewall-cmd --zone=home --add-port=5901/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=5901/tcp
    sudo firewall-cmd --zone=home --add-port=5900/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=5900/tcp
  fi

  # Storage drive
  grep /dev/sda1 /etc/fstab >/dev/null || echo "/dev/sda1 /mnt/storage ext4 rw,user,exec 0 0" | sudo tee -a /etc/fstab > /dev/null
  sudo mkdir -p /mnt/storage
  sudo chmod 777 /mnt/storage

  # Transmission-daemon
  if [ ! -e ~/.config/systemd/user/transmission-daemon.service ]; then
    sed -e "s/PEER_PORT/$mullvad_port/" "$HERE/static/transmission-daemon.service" > ~/.config/systemd/user/transmission-daemon.service
    systemctl --user daemon-reload
    test -e ~/.config/transmission-daemon/settings.json || echo "{}" > ~/.config/transmission-daemon/settings.json
    systemctl --user stop transmission-daemon
    cat ~/.config/transmission-daemon/settings.json \
      | jq '."rpc-enabled" = true' \
      | jq '."rpc-whitelist-enabled" = false' \
      | jq '."script-torrent-done-enabled" = true' \
      | jq '."script-torrent-done-filename" = "'$HOME/dotfiles/static/torrent_done.py'"' \
      > /tmp/settings.json
    mv /tmp/settings.json ~/.config/transmission-daemon/settings.json
    systemctl --user start transmission-daemon
    systemctl --user enable transmission-daemon
  fi

  # VNC
  sudo cp "$HERE/static/vnc.service" /etc/systemd/system/vnc.service
  sudo cp "$HERE/static/x0vnc.sh" /usr/local/bin/x0vnc.sh
  sudo systemctl daemon-reload
  sudo systemctl start vnc

  # TODO
  # remap capslock->ctrl over vnc
  # keyboard shortcuts (workspace switching, launcher, terminal)
  # nerd font
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
  dotcmd-desktop
  echo "Done"
}
