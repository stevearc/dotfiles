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

redshift -l geoclue2 -m randr &

xidlehook \
  --detect-sleep \
  --not-when-fullscreen \
  --not-when-audio \
  --timer 30 \
  'upower -i $(upower -e | grep battery) | grep -q "state.*discharging" && bright set -s -t 1 .2' \
  'bright restore' \
  --timer 150 \
  'bright set -s -t 1 .1' \
  'bright restore' \
  --timer 420 \
  's screenoff' \
  's screenon; bright restore' \
  --timer 10 \
  's lock' \
  's screenon; bright restore' \
  --timer 1200 \
  'sudo pm-suspend' \
  's screenon; bright restore' &
