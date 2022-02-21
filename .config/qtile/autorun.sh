#!/bin/bash
HERE=$(dirname "$(readlink -f "$0")")

setxkbmap -option ctrl:nocaps
xbindkeys
nm-applet &
blueman-applet &

"$HERE/setup-monitors.sh" -f

if command -v picom >/dev/null; then
  picom &
elif command -v compton >/dev/null; then
  compton &
fi

bright set 1
redshift -l geoclue2 -m randr &

xidlehook \
  --detect-sleep \
  --not-when-fullscreen \
  --not-when-audio \
  `# Dim screen after 30s when on battery` \
  --timer 30 \
  'upower -i $(upower -e | grep battery) | grep -q "state.*discharging" && bright set -s -t 1 .01' \
  'upower -i $(upower -e | grep battery) | grep -q "state.*discharging" && bright restore' \
  `# Dim screen after 3m when plugged in` \
  --timer 150 \
  'bright set -s -t 1 .01' \
  'bright restore' \
  `# Turn off screen after 10m` \
  --timer 420 \
  's screenoff' \
  's screenon; bright restore' \
  `# Lock screen 10s after it turns off` \
  --timer 10 \
  's lock' \
  's screenon; bright restore' \
  `# Suspend after 30m` \
  --timer 1200 \
  'sudo pm-suspend' \
  's screenon; bright restore; qtile shell -c "restart()"' &

{
  echo "XIDeviceEnabled XISlaveKeyboard"
  inputplug -d -c /bin/echo
} \
  | while read event; do
    case $event in
      XIDeviceEnabled*XISlaveKeyboard*)
        setxkbmap -option ctrl:nocaps
        ;;
    esac
  done &
