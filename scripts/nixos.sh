#!/bin/bash
set -e

platform-setup() {
  has-checkpoint platform-setup && return
  dotcmd-rebuild
  checkpoint platform-setup
}

# shellcheck disable=SC2034
DOTCMD_DESKTOP_DOC="Install config and settings for desktop environment"
# shellcheck disable=SC2120
dotcmd-desktop() {
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  if [[ $XDG_CURRENT_DESKTOP =~ "GNOME" ]]; then
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
DOTCMD_REBUILD_DOC="Rebuild the nixos config"
# shellcheck disable=SC2120
dotcmd-rebuild() {
  sudo cp "$HERE/nixos/configuration.nix" /etc/nixos/configuration.nix
  sudo nixos-rebuild switch
}
