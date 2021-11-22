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
  'upower -i $(upower -e | grep battery) | grep -q "state.*discharging" && bright set -t 1 .2' \
  'bright set 1' \
  --timer 150 \
  'bright set -t 1 .1' \
  'bright set 1' \
  --timer 420 \
  's screenoff' \
  's screenon; bright set 1' \
  --timer 10 \
  's lock' \
  's screenon; bright set 1' \
  --timer 1200 \
  'pm-suspend' \
  's screenon; bright set 1' &
