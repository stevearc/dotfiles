#!/bin/bash
set -e

platform-setup() {
  # Make pacman display packages in a vertical list
  if ! grep -q "^VerbosePkgLists" /etc/pacman.conf; then
    sudo sed -i -e 's/^.*VerbosePkgLists$/VerbosePkgLists/' /etc/pacman.conf
  fi

  has-checkpoint platform-setup && return

  sudo pacman -Syuq --noconfirm
  sudo pacman -Sq --noconfirm binutils fakeroot curl wget clang base-devel git
  if ! hascmd yay; then
    install-language-go
    pushd /tmp
    [ -e yay ] || git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    popd
  fi
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
  sudo pacman -Syq --noconfirm ninja stylua
  install-lua-ls
}

DC_INSTALL_VIRTMANAGER_DOC="virt-manager virtualization tool"
dc-install-virtmanager() {
  sudo pacman -Syq --noconfirm virt-manager qemu-full virt-viewer dnsmasq vde2 bridge-utils libguestfs
  sudo cp "$HERE/static/libvirtd.conf" /etc/libvirt/libvirtd.conf
  sed -e "s/USER/$USER/" <"$HERE/static/qemu.conf" | sudo tee /etc/libvirt/qemu.conf >/dev/null
  sudo systemctl enable libvirtd
  sudo systemctl start libvirtd
  sudo usermod -a -G libvirt "$USER"
  sudo virsh net-autostart default
}

dc-install-syncthing() {
  sudo pacman -Syq --noconfirm syncthing
  systemctl --user enable syncthing
  systemctl --user start syncthing
  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-service=syncthing
    sudo firewall-cmd --permanent --zone=home --add-service=syncthing
  fi
}

dc-install-plex() {
  pacman -Q | grep -q plex-media-server || yay -Sy --noconfirm plex-media-server
  sudo systemctl start plexmediaserver.service
  sudo systemctl enable plexmediaserver.service
  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-service=plex
    sudo firewall-cmd --zone=home --permanent --add-service=plex
  fi
  test -e /etc/cron.hourly/chown_plex || sudo cp "$HERE/static/chown_plex" /etc/cron.hourly/
}

DC_INSTALL_JELLYFIN_DOC="Jellyfin media server"
dc-install-jellyfin() {
  pacman -Q | grep -q jellyfin-server || pacman -Sy --noconfirm jellyfin-server jellyfin-web jellyfin-ffmpeg
  sudo pacman -Sy --noconfirm rocm-opencl-runtime libva-mesa-driver
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
  # Add jellyfin to the video group for hardware acceleration
  sudo -u jellyfin groups | grep video || sudo usermod -aG video jellyfin
  sudo -u jellyfin groups | grep render || sudo usermod -aG render jellyfin
  # To enable hardware acceleration, you also need to enable V4L2 in the Jellyfin interface
}

# shellcheck disable=SC2034
DC_INSTALL_COMMON_DOC="Common unix utilities like tmux, netcat, etc"
dc-install-common() {
  sudo pacman -Syq --noconfirm \
    fzf \
    gnu-netcat \
    htop \
    inotify-tools \
    iotop \
    jq \
    less \
    lsof \
    man \
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
  hascmd fswatch || yay -S --noconfirm fswatch
}

# shellcheck disable=SC2034
DC_INSTALL_NEOVIM_DOC="<3"
dc-install-neovim() {
  if ! hascmd nvim; then
    sudo pacman -Syq --noconfirm neovim
  fi
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
  dc-install-nerd-font
  sudo pacman -Syq --noconfirm \
    bluedevil \
    bluez \
    ffmpeg \
    flatpak \
    firefox \
    gtk2 \
    kdeconnect \
    kitty \
    libnotify \
    nfs-utils \
    sshfs \
    steam \
    vlc \
    wl-clipboard \
    zenity
  hascmd tomb || yay -S --noconfirm tomb # gtk2 above is a dependency
  if ! pacman -Qm | grep -q xpadneo; then
    sudo pacman -Syq --noconfirm linux-headers
    yay -S --noconfirm xpadneo-dkms
  fi
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
    openssh \
    transmission-cli

  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
  sudo systemctl enable cronie.service
  sudo systemctl start cronie.service

  test -e /etc/cron.hourly/rsync_torrents || sudo cp "$HERE/static/rsync_torrents" /etc/cron.hourly/

  # faster startup
  if [ -e /etc/default/grub ] && ! grep -q GRUB_TIMEOUT=1 /etc/default/grub; then
    sudo sed -i -e 's/^GRUB_TIMEOUT.*$/GRUB_TIMEOUT=1/' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi

  # Transmission-daemon
  if [ ! -e /etc/systemd/system/transmission-daemon.service ]; then
    sudo cp "$HERE/static/transmission-daemon.service" /etc/systemd/system/transmission-daemon.service
    sudo systemctl daemon-reload
    mkdir -p ~/.config/transmission-daemon
    test -e ~/.config/transmission-daemon/settings.json || echo "{}" >~/.config/transmission-daemon/settings.json
    sudo systemctl stop transmission-daemon
    cat ~/.config/transmission-daemon/settings.json |
      jq '."rpc-enabled" = true' |
      jq '."rpc-whitelist-enabled" = false' |
      jq '."script-torrent-done-enabled" = true' |
      jq '."script-torrent-done-filename" = "'$HOME/dotfiles/static/torrent_done.py'"' \
        >/tmp/settings.json
    mv /tmp/settings.json ~/.config/transmission-daemon/settings.json
    sudo systemctl enable transmission-daemon
    sudo systemctl start transmission-daemon
  fi

  # Port forwarding
  if [ ! -e /etc/systemd/system/proton-port-forward.service ]; then
    sudo cp "$HERE/static/proton-port-forward.service" /etc/systemd/system/proton-port-forward.service
    sudo systemctl enable proton-port-forward
    sudo systemctl daemon-reload
    sudo systemctl start proton-port-forward
  fi

  setup-kde
  kde-auto-login
  dotcmd-virt-shared-folder storage /mnt/storage
  dc-install-protonvpn
  dc-install-power-always-on
}

dc-install-protonvpn() {
  sudo pacman -Syq --noconfirm wireguard-tools systemd-resolvconf
  sudo systemctl enable --now systemd-resolved
  if sudo test ! -e /etc/wireguard/US.conf; then
    echo "Download a wireguard conf and put it in /etc/wireguard/"
    echo "Put the following lines under the [Interface]"
    echo '    PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT'
    echo '    PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT'
    echo "Then symlink it to /etc/wireguard/US.conf"
    read -r
    xdg-open https://account.protonvpn.com/downloads
  fi
  sudo systemctl enable wg-quick@US.service
  sudo systemctl daemon-reload
  sudo systemctl start wg-quick@US
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

DC_INSTALL_POWER_ALWAYS_ON="Set KDE settings to never suspend"
dc-install-power-always-on() {
  cat >~/.config/powerdevilrc <<EOF
[AC][Display]
TurnOffDisplayIdleTimeoutSec=-1
TurnOffDisplayWhenIdle=false

[AC][SuspendAndShutdown]
AutoSuspendAction=0
PowerButtonAction=8
EOF
  cat >~/.config/kscreenlockerrc <<EOF
[Daemon]
Autolock=false
Timeout=0
EOF
}

dotcmd-beelink() {
  sudo pacman -Syq --noconfirm cronie nfs-utils
  sudo systemctl enable cronie.service
  sudo systemctl start cronie.service
  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
  dc-install-common
  dc-install-neovim
  dotcmd-desktop
  kde-auto-login
  dc-install-power-always-on
  dc-install-plex
  dc-install-virtmanager
  sudo cp "$HERE/static/rsync_retroarch_saves" /etc/cron.hourly/
  sudo cp "$HERE/static/create_symbolic_archive.py" /etc/cron.hourly/create_symbolic_archive
  sudo cp "$HERE/static/storage_backup" /etc/cron.d/storage_backup
  sudo chown root:root /etc/cron.d/storage_backup
  sudo chmod 644 /etc/cron.d/storage_backup
  mkdir -p ~/.config/autostart
  cp "$HERE/static/autostart/steam.desktop" ~/.config/autostart/

  if [ ! -e /etc/exports.d/nfs-storage.exports ]; then
    sudo cp "$HERE/static/nfs-storage.exports" /etc/exports.d/
    sudo exportfs -arv
    sudo systemctl enable nfs-server.service
    sudo systemctl start nfs-server.service
  fi

  if hascmd firewall-cmd; then
    sudo firewall-cmd --zone=home --add-port=2049/tcp
    sudo firewall-cmd --permanent --zone=home --add-port=2049/tcp
  fi

  # set up drive
  sudo mkdir -p /mnt/storage
  if ! grep -q '/mnt/storage' /etc/fstab; then
    echo -e "UUID=4f0ff868-2052-4a18-b683-f4abc2bd0233\t/mnt/storage\text4\trw,relatime\t0\t0" | sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
    sudo mount -a
  fi
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

  grep "$MEDIA_SERVER_IP" /etc/fstab >/dev/null || echo "${MEDIA_SERVER_IP}:/mnt/storage /mnt/storage nfs _netdev,noauto,x-systemd.automount,x-systemd.mount-timeout=10,timeo=14,x-systemd.idle-timeout=1min  0 0" | sudo tee -a /etc/fstab >/dev/null
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
