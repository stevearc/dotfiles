#!/bin/bash
set -e
declare -r XFCE_DOTFILES=".xsessionrc"
declare -r DESKTOP_CONFIGS="
  alacritty
  dolphinrc
	dunst
  kitty
  latte
  lattedockrc
  lightlyrc
  ncmpcpp
  oxygenrc
  qtile
  rofi
  yamllint
  kxkbrc
  krunnerrc
  kglobalshortcutsrc
"

setup-gnome() {
  cp "$HERE/static/mimeapps.list" ~/.local/share/applications

  # Find schema with 'dconf watch /' and then changing the settings
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.media-keys search "['<Super>space']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Shift><Alt>Return']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Alt>1']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Alt>2']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Alt>3']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Alt>4']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Alt>exclam']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Alt>at']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Alt>numbersign']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Alt>dollar']"
  gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>w']"
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>m']"
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
  gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 24
  gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor 0
  gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
  gsettings set org.gnome.desktop.session idle-delay 900
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.mutter workspaces-only-on-primary false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
  gsettings set org.gnome.mutter edge-tiling true
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.interface clock-show-weekday true

  dconf write /org/gnome/terminal/legacy/new-terminal-mode '"window"'
  local term_profile
  term_profile=$(dconf read /org/gnome/terminal/legacy/profiles:/list | tr "'" '"' | jq -r '.[0]')
  dconf write "/org/gnome/terminal/legacy/profiles:/:$term_profile/use-system-font" false
  dconf write "/org/gnome/terminal/legacy/profiles:/:$term_profile/audible-bell" false
  dconf write "/org/gnome/terminal/legacy/profiles:/:$term_profile/text-blink-mode" '"never"'
  dconf write "/org/gnome/terminal/legacy/profiles:/:$term_profile/font" '"UbuntuMono Nerd Font 12"'

  if [ "$(dconf read "/org/gnome/terminal/legacy/profiles:/$term_profile/use-theme-colors")" == "true" ]; then
    pushd /tmp
    if [ ! -e gnome-terminal ]; then
      git clone https://github.com/dracula/gnome-terminal
    fi
    cd gnome-terminal
    ./install.sh -s Dracula -p "$term_profile" --skip-dircolors
    popd
  fi
}

setup-kde() {
  for conf in $DESKTOP_CONFIGS; do
    local src="$HERE/.config/$conf"
    local dest="${XDG_CONFIG_HOME-$HOME/.config}/$conf"
    if [ -e "$src" ]; then
      mirror "$src" "$dest" 1
    fi
  done
  sudo pacman -Syq --noconfirm qt5-tools
  mkdir -p ~/.config/plasma-workspace/env
  cat >~/.config/plasma-workspace/env/path.sh <<EOF
#!/bin/bash
export PATH=\$HOME/.local/bin:\$PATH
EOF
  if hascmd ufw; then
    sudo ufw allow proto udp from 192.168.1.0/24 to any port 1714:1764 comment 'kdeconnect'
    sudo ufw allow proto tcp from 192.168.1.0/24 to any port 1714:1764 comment 'kdeconnect'
    # sudo ufw allow proto udp from 2a02:xxxx:xxxx:xxxx::/64 to any port 1714:1764 comment 'kdeconnect'
    # sudo ufw allow proto tcp from 2a02:xxxx:xxxx:xxxx::/64 to any port 1714:1764 comment 'kdeconnect'
  fi
  if hascmd firewall-cmd; then
    firewall-cmd --zone=home --add-service=kdeconnect
    firewall-cmd --permanent --zone=home --add-service=kdeconnect
  fi
  # Disable baloo file indexer
  hascmd balooctl && balooctl disable
  # Disable screen corner magic [Workspace Behavior > Screen Edges]
  for pos in Bottom BottomLeft BottomRight Left Right Top TopLeft TopRight; do
    kwriteconfig6 --file ~/.config/kwinrc --group ElectricBorders --key "$pos" None
  done
  # Four virtual desktops [Workspace Behavior > Virtual Desktops]
  for i in 1 2 3 4; do
    grep -q "^Id_$i=" ~/.config/kwinrc || kwriteconfig6 --file ~/.config/kwinrc --group Desktops --key "Id_$i" "$(python -c "import uuid; print(str(uuid.uuid4()))")"
  done
  kwriteconfig6 --file ~/.config/kwinrc --group Desktops --key Number 4
  kwriteconfig6 --file ~/.config/kwinrc --group Desktops --key Rows 1
  # Immediate desktop switch [Workspace Behavior > Virtual Desktops]
  kwriteconfig6 --file ~/.config/kwinrc --group Plugins --key slideEnabled false
  # Faster animations [Workspace Behavior > General Behavior]
  kwriteconfig6 --file ~/.config/kdeglobals --group KDE --key AnimationDurationFactor 0.125
  kwriteconfig6 --file ~/.config/kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
  # Hide title bar for maximized windows
  kwriteconfig6 --file ~/.config/kwinrc --group Windows --key BorderlessMaximizedWindows true
}

kde-auto-login() {
  sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key Relogin false
  sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key User "$USER"
  sudo kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key Session plasma
}

setup-xfce() {
  sudo cp "$HERE/static/00-keyboard.conf" /etc/X11/xorg.conf.d/00-keyboard.conf
}

# shellcheck disable=SC2034
DOTCMD_SAVE_DESKTOP_CONFIG_DOC="Save desktop config files to repo"
dotcmd-save-desktop-config() {
  for conf in $DESKTOP_CONFIGS; do
    local src="${XDG_CONFIG_HOME-$HOME/.config}/$conf"
    if [ -e "$src" ] && [ ! -L "$src" ]; then
      cp -r "$src" "$HERE/.config/$conf"
    fi
  done
}

setup-xfce() {
  # Remap caps lock to control
  if ! grep "XKBOPTIONS.*ctrl:nocaps" /etc/default/keyboard >/dev/null; then
    sudo sed -ie 's/XKBOPTIONS=.*/XKBOPTIONS="ctrl:nocaps"/' /etc/default/keyboard
    sudo dpkg-reconfigure keyboard-configuration
  fi

  cp -r "$XFCE_DOTFILES" "$HOME"
  mkdir -p ~/.config
  rsync -lrp .config/xfce4 ~/.config/
  rsync -lrp .config/autostart ~/.config/
}

setup-desktop-generic() {
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  if [ ! -e ~/.config/backgrounds ]; then
    mkdir -p ~/.config/backgrounds
    cd ~/.config/backgrounds
    wget https://images6.alphacoders.com/805/805740.png
  fi
  if [ ! -e /etc/udev/rules.d/backlight.rules ]; then
    sudo usermod -a -G video "$USER"
    cat >/tmp/backlight.rules <<EOF
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", GROUP="video", MODE="0664"
RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
EOF
    sudo mv /tmp/backlight.rules /etc/udev/rules.d/backlight.rules
  fi
  sed -e "s/^USER/$USER/" "$HERE/static/pm-no-sudo" | sudo tee /etc/sudoers.d/pm-no-sudo >/dev/null
  sed -e "s/^USER/$USER/" "$HERE/static/loadkeys-no-sudo" | sudo tee /etc/sudoers.d/loadkeys-no-sudo >/dev/null
  if ! hascmd yt-dlp; then
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ~/.local/bin/yt-dlp
    chmod +x ~/.local/bin/yt-dlp
  fi
  flatpak install --user --noninteractive flathub com.spotify.Client com.discordapp.Discord com.google.Chrome org.signal.Signal
  flatpak install --system flathub com.github.tchx84.Flatseal
  dc-install-rclone
}

# shellcheck disable=SC2034
DC_INSTALL_NERD_FONT_DOC="Font with icons"
dc-install-nerd-font() {
  mkdir -p ~/.local/share/fonts
  pushd ~/.local/share/fonts >/dev/null
  if [ ! -e "Ubuntu Mono Nerd Font Complete.ttf" ]; then
    fetch-nerd-font
  fi
  popd >/dev/null
}
