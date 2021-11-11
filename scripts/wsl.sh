#!/bin/bash
set -e

winsudo() {
  if [ -z "$WSL" ]; then
    echo "Cannot use winsudo if not in WSL"
    return
  fi
  powershell.exe -command "start-process -verb runas powershell" "'-command $*'"
}

wsl-setup() {
  if [ -e "$C_DRIVE/tmp" ]; then
    rm -rf "$C_DRIVE/tmp"
  fi
  if [ ! -e "$C_DRIVE/Windows/System32/win32yank.exe" ]; then
    pushd /tmp
    wget https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
    unzip win32yank-x64.zip
    mkdir -p "$C_DRIVE/tmp"
    mv win32yank.exe "$C_DRIVE/tmp"
    winsudo mv 'C:\tmp\win32yank.exe' 'C:\Windows\System32\'
    popd
  fi
  if [ ! -e "/etc/wsl.conf" ]; then
    echo -e "[automount]\noptions = case=off" | sudo tee /etc/wsl.conf
  fi
}

# shellcheck disable=SC2034
DC_INSTALL_WSL_PACKAGES_DOC="Windows packages (steam, chrome, slack, etc)"
dc-install-wsl-packages() {
  winsudo choco install -y chocolatey vlc skype googlechrome discord slack steam dropbox calibre dolphin mupen64plus geforce-experience sharpkeys
  if [ ! -e "$C_DRIVE/Program Files/Unity Hub" ]; then
    pushd /tmp
    [ ! -e UnityHubSetup.exe ] && wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe
    mkdir -p "$C_DRIVE/tmp"
    mv UnityHubSetup.exe "$C_DRIVE/tmp"
    winsudo 'C:\tmp\UnityHubSetup.exe'
    popd
  fi
}
