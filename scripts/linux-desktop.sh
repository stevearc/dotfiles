#!/bin/bash
set -e
declare -r XFCE_DOTFILES=".xsessionrc"
declare -r DESKTOP_CONFIGS="
  Kvantum
  breezerc
  dolphinrc
  gtk-2.0
  gtk-3.0
  gtk-4.0
  gtkrc
  gtkrc-2.0
  kcminputrc
  kdeglobals
  kglobalshortcutsrc
  khotkeysrc
  klipperrc
  konsolerc
  krunnerrc
  kscreenlockerrc
  ksmserverrc
  ksplashrc
  kwinrc
  kwinrulesrc
  kxkbrc
  latte
  lattedockrc
  lightlyrc
  ncmpcpp
  oxygenrc
  plasma-org.kde.plasma.desktop-appletsrc
  plasmarc
  plasmashellrc
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

# shellcheck disable=SC2034
DC_INSTALL_CLIPPER_DOC="Clipper (networked clipboard sharing)"
dc-install-clipper() {
  if ! nc -z localhost 8377; then
    install-language-go
    go get github.com/wincent/clipper
    go build github.com/wincent/clipper
    sudo cp "$GOPATH/bin/clipper" /usr/local/bin
    if hascmd systemctl; then
      mkdir -p ~/.config/systemd/user
      cp "$GOPATH/src/github.com/wincent/clipper/contrib/linux/systemd-service/clipper.service" ~/.config/systemd/user
      sed -ie 's|^ExecStart.*|ExecStart=/usr/local/bin/clipper -l /var/log/clipper.log -e xsel -f "-bi"|' ~/.config/systemd/user/clipper.service
      systemctl --user daemon-reload
      systemctl --user enable clipper.service
      systemctl --user start clipper.service
    else
      sudo cp clipper.conf /etc/init
      sudo service clipper start
    fi
  fi
}

# shellcheck disable=SC2034
DC_INSTALL_NERD_FONT_DOC="Font with icons"
dc-install-nerd-font() {
  mkdir -p ~/.local/share/fonts
  pushd ~/.local/share/fonts
  if [ ! -e UbuntuMono.zip ]; then
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/UbuntuMono.zip
    unzip UbuntuMono.zip
  fi
  popd
}
