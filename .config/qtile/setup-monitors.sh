#!/bin/bash
set -e

num_monitors=$(xrandr | grep "\bconnected" -c)
monitor_config="$HOME/.screenlayout/layout${num_monitors}.sh"
if [ -e "$monitor_config" ]; then
  if ! grep -q "$monitor_config" ~/.cache/qtile/last_layout 2>/dev/null || [ "$1" == "-f" ]; then
    echo "run $(basename "$monitor_config")"
    echo -n "$monitor_config" >~/.cache/qtile/last_layout
    "$monitor_config"
  fi
fi
