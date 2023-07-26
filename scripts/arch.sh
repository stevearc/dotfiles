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

DC_INSTALL_VIRTMANAGER_DOC="virt-manager virtualization tool"
dc-install-virtmanager() {
  sudo pacman -Syq --noconfirm virt-manager qemu virt-viewer dnsmasq vde2 bridge-utils libguestfs
  sudo cp "$HERE/static/libvirtd.conf" /etc/libvirt/libvirtd.conf
  sed -e "s/USER/$USER/" <"$HERE/static/qemu.conf" | sudo tee /etc/libvirt/qemu.conf >/dev/null
  sudo systemctl enable libvirtd
  sudo systemctl start libvirtd
  sudo usermod -a -G libvirt "$USER"
}

DC_INSTALL_JELLYFIN_DOC="Jellyfin media server"
dc-install-jellyfin() {
  pacman -Qm | grep -q jellyfin-bin || yay -S --noconfirm jellyfin-bin
  sudo systemctl start jellyfin.service
  sudo systemctl enable jellyfin.service
  if hascmd ufw; then
    sudo ufw allow proto udp from 192.168.1.0/24 to any port 8096 comment 'jellyfin'
    sudo ufw allow proto tcp from 192.168.1.0/24 to any port 8096 comment 'jellyfin'
  fi
  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-port=8096/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=8096/tcp
  fi
  test -e /etc/cron.hourly/chown_jellyfin || sudo cp "$HERE/static/chown_jellyfin" /etc/cron.hourly/
  sudo cp "$HERE/static/jellyfin_conf" /etc/conf.d/jellyfin
  # Add jellyfin to the video group for hardware acceleration
  sudo -u jellyfin groups | grep video || sudo usermod -aG video jellyfin
  # To enable hardware acceleration, you also need to enable V4L2 in the Jellyfin interface
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
    tldr \
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
    sudo pacman -Syq --noconfirm neovim
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
    ffmpeg \
    flatpak \
    gtk2 \
    kitty \
    libnotify \
    steam \
    vlc \
    zenity
  hascmd tomb || yay -S --noconfirm tomb # gtk2 above is a dependency
  pacman -Qm | grep -q xpadneo || yay -S --noconfirm xpadneo-dkms
  setup-desktop-generic
  sudo systemctl enable bluetooth.service
  sudo systemctl restart bluetooth.service
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
  sudo cp "$HERE/static/NetworkManager.conf" /etc/NetworkManager
  if ! ifconfig wlan0 | grep -q inet; then
    nmcli dev wifi connect slugnet -a
  fi

  dc-install-common
  dc-install-neovim
  dotcmd-dotfiles
  dc-install-nerd-font
  sudo pacman -Syq --noconfirm \
    cronie \
    dialog \
    dhcpcd \
    fuse2 \
    kitty \
    nfs-utils \
    openssh \
    transmission-cli
  dc-install-kitty
  dc-install-airvpn
  # This is configured on the AirVPN website
  local vpn_port=23701

  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
  sudo systemctl enable cronie.service
  sudo systemctl start cronie.service

  test -e /etc/cron.hourly/rsync_torrents || sudo cp "$HERE/static/rsync_torrents" /etc/cron.hourly/

  if sudo firewall-cmd --state; then
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
    if [ -n "$vpn_port" ]; then
      sudo firewall-cmd --zone=home --add-port="${vpn_port}/tcp"
      sudo firewall-cmd --permanent --zone=home --add-port="${vpn_port}/tcp"
      sudo firewall-cmd --zone=public --add-port="${vpn_port}/tcp"
      sudo firewall-cmd --permanent --zone=public --add-port="${vpn_port}/tcp"
    fi
  fi

  # Storage drive
  dc-install-nfs-mount

  # Transmission-daemon
  if [ ! -e /etc/systemd/system/transmission-daemon.service ]; then
    sed -e "s/PEER_PORT/$vpn_port/" "$HERE/static/transmission-daemon.service" | sudo tee /etc/systemd/system/transmission-daemon.service >/dev/null
    sudo systemctl daemon-reload
    test -e ~/.config/transmission-daemon/settings.json || echo "{}" >~/.config/transmission-daemon/settings.json
    sudo systemctl stop transmission-daemon
    cat ~/.config/transmission-daemon/settings.json \
      | jq '."rpc-enabled" = true' \
      | jq '."rpc-whitelist-enabled" = false' \
      | jq '."script-torrent-done-enabled" = true' \
      | jq '."script-torrent-done-filename" = "'$HOME/dotfiles/static/torrent_done.py'"' \
        >/tmp/settings.json
    mv /tmp/settings.json ~/.config/transmission-daemon/settings.json
    sudo systemctl enable transmission-daemon
    sudo systemctl start transmission-daemon
  fi
}

DC_INSTALL_DOLPHIN_DOC="The Dolphin core for RetroArch"
dc-install-dolphin() {
  local base="$HOME/.local/share/Steam/steamapps/common/RetroArch"
  if [ ! -e "$base" ]; then
    echo "Error: could not find RetroArch Steam installation in $base"
    return 1
  fi
  mkdir -p /tmp/dolphin-workspace
  pushd /tmp/dolphin-workspace >/dev/null
  [ -e dolphin_libretro.so.zip ] || wget https://buildbot.libretro.com/nightly/linux/x86_64/latest/dolphin_libretro.so.zip
  [ -e info.zip ] || wget https://buildbot.libretro.com/assets/frontend/info.zip
  [ -e Dolphin.zip ] || wget https://buildbot.libretro.com/assets/system/Dolphin.zip

  unzip -o dolphin_libretro.so.zip
  unzip -o info.zip
  unzip -o Dolphin.zip

  cp dolphin_libretro.so "$base/cores"
  cp dolphin_libretro.info "$base/cores"
  rm -rf "$base/system/dolphin-emu"
  cp -r dolphin-emu "$base/system"
  popd >/dev/null
}

dotcmd-beelink() {
  sudo pacman -Syq --noconfirm cronie
  sudo systemctl enable cronie.service
  sudo systemctl start cronie.service
  dc-install-common
  dc-install-neovim
  dotcmd-desktop
  dc-install-jellyfin
  sudo cp "$HERE/static/rsync_retroarch_saves" /etc/cron.hourly/
  sudo cp "$HERE/static/create_symbolic_archive.py" /etc/cron.hourly/create_symbolic_archive
  sudo cp "$HERE/static/storage_backup" /etc/cron.d/storage_backup
  sudo chown root:root /etc/cron.d/storage_backup
  sudo chmod 644 /etc/cron.d/storage_backup
  mkdir -p ~/.config/autostart
  cp "$HERE/static/autostart/steam.desktop" ~/.config/autostart/
}

dc-install-rclone() {
  hascmd rclone || sudo pacman -Syq --noconfirm rclone
}

dc-install-airvpn() {
  local version="1.3.0"
  if ! hascmd goldcrest; then
    pushd /tmp >/dev/null
    local architecture
    if [ ! -e AirVPN-Suite ]; then
      if [ ! -e AirVPN-Suite.tar.gz ]; then
        architecture="$(lscpu | grep Architecture | awk '{print $2}')"
        local url="https://gitlab.com/AirVPN/AirVPN-Suite/-/raw/master/binary/AirVPN-Suite-${architecture}-${version}.tar.gz?inline=false"
        curl "$url" -o AirVPN-Suite.tar.gz
      fi
      tar -zxf AirVPN-Suite.tar.gz
    fi
    cd AirVPN-Suite
    sudo ./install.sh
    sudo usermod -aG airvpn "$USER"
    popd >/dev/null
  fi

  _set_airvpn_config airconnectatboot quick
  _set_airvpn_config networklockpersist on
  _set_airvpn_config airusername stevearc
  _set_airvpn_config country US
  if ! sudo grep -q "^airpassword " /etc/airvpn/bluetit.rc; then
    read -r -p "AirVPN password? " air_password
    _set_airvpn_config airpassword "$air_password"
  fi
}

_set_airvpn_config() {
  local key="${1?Usage: _set_airvpn_config [key] [value]}"
  local value="${2?Usage: _set_airvpn_config [key] [value]}"
  sudo sed -i -e "/^${key}\\s/d" /etc/airvpn/bluetit.rc
  echo -e "$key\t$value" | sudo tee -a /etc/airvpn/bluetit.rc >/dev/null
}

dc-install-calibreweb() {
  mkdir -p ~/.envs
  pushd ~/.envs >/dev/null
  if [ ! -e calibre ]; then
    python -m venv calibre
  fi
  if [ ! -e calibre/bin/cps ]; then
    source ./calibre/bin/activate
    pip install --upgrade pip wheel
    pip install calibreweb
    deactivate
  fi
  popd >/dev/null

  cp "$HERE/static/calibre.service" "$HOME/.config/systemd/user"
  systemctl --user daemon-reload
  systemctl --user start calibre
  systemctl --user enable calibre

  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-port=8083/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=8083/tcp
  fi
}

dc-install-nfs-mount() {
  sudo mkdir -p /mnt/storage

  grep "$MEDIA_SERVER_IP" /etc/fstab >/dev/null || echo "${MEDIA_SERVER_IP}:/mnt/storage   /mnt/storage   nfs   defaults,timeo=900,retrans=5,_netdev	0 0" | sudo tee -a /etc/fstab >/dev/null
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
