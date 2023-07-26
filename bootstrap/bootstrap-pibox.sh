#!/bin/bash
set -e
# Boot from endeavouros live disk in main computer
# insert SD card and click the "install arm" button
# Remember that the device must be specified as a full path (e.g. /dev/mmcblk0)
# If Rpi doesn't have video out after boot, open /boot/config.txt and comment out the dtoverlay line

IFACE="$(iw dev | grep Interface | awk '{print $2}')"
ESSID="slugnet"
# Find this information with ifconfig and nmcli -f SSID,BSSID,ACTIVE dev wifi list
GATEWAY="192.168.50.1"
BSSID="04:42:1A:CC:E8:44"

setup-wifi() {
  ping -c www.google.com && return
  sudo killall wpa_supplicant || :

  if [ ! -e "/etc/wpa_supplicant/$ESSID.conf" ]; then
    sudo mkdir -p /etc/wpa_supplicant
    wpa_passphrase "$ESSID" "${WIFI_SECRET?Need wifi password as export WIFI_SECRET=sekrit}" | sudo tee "/etc/wpa_supplicant/$ESSID.conf" >/dev/null
  fi
  sudo wpa_supplicant -B -c "/etc/wpa_supplicant/$ESSID.conf" -i "$IFACE"
  sudo ifconfig "$IFACE" down
  sudo iwconfig "$IFACE" essid "$ESSID"
  sudo iwconfig "$IFACE" ap "$BSSID"
  sudo ifconfig "$IFACE" up
  sudo route add "$GATEWAY" dev "$IFACE"
  sudo route add default gw "$GATEWAY"
}

setup-stevearc() {
  sudo grep stevearc /etc/shadow && return
  sudo useradd --groups wheel --create-home stevearc
  sudo mkdir -p /etc/sudoers.d
  echo "stevearc ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stevearc
  sudo passwd stevearc
}

setup-wifi
sudo pacman-key -u
sudo pacman-key --populate
setup-stevearc

cd /home/stevearc
sudo -u stevearc test -e dotfiles || git clone https://github.com/stevearc/dotfiles
cd dotfiles
sudo -u stevearc ./run pibox
