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

  # Global shortcuts
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group khotkeys --key '{3266e259-e66d-4ae2-b7bd-b013fb04b811}' "Alt+Shift+R,none,KRunner"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group khotkeys --key '{686a288d-cf2e-4345-bc3d-bde3b6aa2229}' "Ctrl+Alt+T,none,Launch Konsole"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group khotkeys --key '{6b5c0aeb-f76a-48c4-b890-e997d33083ec}' "Alt+Shift+Return,none,Kitty"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group khotkeys --key '{94d72d73-7359-4a07-bf76-1be49f4b577c}' "Alt+Shift+P,none,KRunner"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group org.kde.krunner.desktop --key '_launch' "$(echo -e "Search\tAlt+Space\tAlt+Shift+P,Alt+Space\tAlt+F2\tSearch,KRunner")"

  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Close' "Alt+W,Alt+F4,Close Window"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Fullscreen' "F11,none,Make Window Fullscreen"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Maximize' "Alt+Return,none,Maximize Window"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Bottom' "Alt+Down,Meta+Down,Quick Tile Window to the Bottom"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Bottom Left' "Alt+Shift+Left,none,Quick Tile Window to the Bottom Left"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Bottom Right' "Alt+Shift+Down,none,Quick Tile Window to the Bottom Right"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Left' "Alt+Left,Meta+Left,Quick Tile Window to the Left"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Right' "Alt+Right,Meta+Right,Quick Tile Window to the Right"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Top' "Alt+Up,Meta+Up,Quick Tile Window to the Top"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Top Left' "Alt+Shift+Up,none,Quick Tile Window to the Top Left"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window Quick Tile Top Right' "Alt+Shift+Right,none,Quick Tile Window to the Top Right"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Switch to Desktop 1' "Alt+1,Ctrl+F1,Switch to Desktop 1"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Switch to Desktop 2' "Alt+2,Ctrl+F2,Switch to Desktop 2"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Switch to Desktop 3' "Alt+3,Ctrl+F3,Switch to Desktop 3"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Switch to Desktop 4' "Alt+4,Ctrl+F4,Switch to Desktop 4"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window to Desktop 1' "Alt+!,none,Window to Desktop 1"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window to Desktop 2' "Alt+@,none,Window to Desktop 2"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window to Desktop 3' "Alt+#,none,Window to Desktop 3"
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group kwin --key 'Window to Desktop 4' 'Alt+$,none,Window to Desktop 4'
  kwriteconfig6 --file ~/.config/kglobalshortcutsrc --group ksmserver --key "Lock Session" "$(echo -e "Meta+L\tCtrl+Alt+L\tScreensaver,Meta+L\tCtrl+Alt+L\tScreensaver,Lock Session")"

  # Krunner
  kwriteconfig6 --file ~/.config/krunnerrc --group General --key "FreeFloating" "true"
  kwriteconfig6 --file ~/.config/krunnerrc --group Plugins --key "bookmarksEnabled" "false"
  kwriteconfig6 --file ~/.config/krunnerrc --group Plugins --key "calculatorEnabled" "false"
  kwriteconfig6 --file ~/.config/krunnerrc --group Plugins --key "recentdocumentsEnabled" "false"
  kwriteconfig6 --file ~/.config/krunnerrc --group Plugins --key "webshortcutsEnabled" "false"

  # Make capslock control
  kwriteconfig6 --file ~/.config/kxkbrc --group Layout Options "caps:ctrl_modifier"

  # Hide title bar for maximized windows
  kwriteconfig6 --file ~/.config/kwinrc --group Windows --key BorderlessMaximizedWindows true

  # Reload changes
  qdbus org.kde.KWin /KWin reconfigure
  qdbus org.kde.keyboard /modules/khotkeys reread_configuration
  kquitapp6 plasmashell
  kstart5 plasmashell
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
  dc-install-kitty
  dc-install-rclone
}

# shellcheck disable=SC2034
DC_INSTALL_XPADNEO_DOC="Drivers for Xbox controller"
dc-install-xpadneo() {
  pushd /tmp >/dev/null
  local latest_release
  latest_release="$(curl -s https://api.github.com/repos/atar-axis/xpadneo/releases | jq -r ".[].tag_name" | sort -V -r | head -1)"
  if [ ! -e xpadneo ]; then
    git clone https://github.com/atar-axis/xpadneo.git
  fi
  cd xpadneo
  git fetch --tags
  git checkout "$latest_release"
  sudo ./uninstall.sh || :
  sudo ./install.sh
  popd >/dev/null
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
