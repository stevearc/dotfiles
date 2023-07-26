#!/bin/bash
set -e
IFACE="$(iw dev | grep Interface | awk '{print $2}')"
ESSID="slugnet"
# Find this information with ifconfig and nmcli -f SSID,BSSID,ACTIVE dev wifi list
GATEWAY="192.168.50.1"
BSSID="04:42:1A:CC:E8:44"

if [ "$1" == "manual" ]; then
  sudo systemctl stop NetworkManager.service
  sudo systemctl stop NetworkManager-wait-online.service
  sudo systemctl stop NetworkManager-dispatcher.service
  sudo systemctl stop network-manager.service
  sudo systemctl stop wpa_supplicant.service
  sudo killall wpa_supplicant || :

  if [ ! -e "/etc/wpa_supplicant/$ESSID.conf" ]; then
    sudo mkdir -p /etc/wpa_supplicant
    wpa_passphrase "$ESSID" "${SECRET?Need wifi password as export SECRET=sekrit}" | sudo tee "/etc/wpa_supplicant/$ESSID.conf" >/dev/null
  fi
  sudo wpa_supplicant -B -c "/etc/wpa_supplicant/$ESSID.conf" -i "$IFACE"
  sudo ifconfig "$IFACE" down
  sudo iwconfig "$IFACE" essid "$ESSID"
  sudo iwconfig "$IFACE" ap "$BSSID"
  sudo ifconfig "$IFACE" up
  sudo route add "$GATEWAY" dev "$IFACE"
  sudo route add default gw "$GATEWAY"
  sleep 1
  sudo dhclient
elif [ "$1" == "auto" ]; then
  sudo killall wpa_supplicant || :
  sudo systemctl start NetworkManager.service
  sudo systemctl start NetworkManager-wait-online.service
  sudo systemctl start NetworkManager-dispatcher.service
  sudo systemctl start network-manager.service
  sudo systemctl stop wpa_supplicant.service
  sudo systemctl start wpa_supplicant.service
else
  echo "$0 [manual|auto]"
fi
