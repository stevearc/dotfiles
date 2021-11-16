#!/bin/bash
HERE=$(dirname "$(readlink -f "$0")")

rm -f ~/.cache/qtile/screenoff
setxkbmap -option ctrl:nocaps

"$HERE/setup-monitors.sh" -f

if command -v picom >/dev/null; then
  picom &
elif command -v compton >/dev/null; then
  compton &
fi

xidlehook \
  --detect-sleep \
  --not-when-fullscreen \
  --not-when-audio \
  --timer 600 \
  's screenoff' \
  's screenon' \
  --timer 10 \
  's lock' \
  's screenon' \
  --timer 1200 \
  'pm-suspend' \
  's screenon' &
