#!/bin/bash
set -e

cleanup() {
  rm -rf ~/.local/share/appimages/squashfs-root
}
trap cleanup SIGINT SIGTERM EXIT

main() {
  local img=${1?Usage: $0 <appimage>}
  if [ ! -e "$img" ]; then
    echo "cannot find file '$img'" >&2
    exit 1
  fi
  mkdir -p ~/.local/share/appimages/icons
  mv "$img" ~/.local/share/appimages 2>/dev/null || :
  img=$(basename "$img")
  cd ~/.local/share/appimages
  rm -rf squashfs-root
  "./$img" --appimage-extract >/dev/null
  cd squashfs-root
  ls

  local app
  app=$(find . -maxdepth 1 -name '*.desktop')
  if [ -z "$app" ]; then
    echo "Could not find .desktop file" >&2
    exit 1
  fi

  local icon_name
  icon_name=$(grep -m1 '^Icon=' "$app" | cut -d= -f2)
  if [ -z "$icon_name" ]; then
    echo "Could not find Icon= in .desktop file" >&2
    exit 1
  fi
  local icon_file="${icon_name}.png"
  cp -L "$icon_file" ~/.local/share/appimages/icons

  setval "$app" "Exec" "$HOME/.local/share/appimages/$img"
  setval "$app" "Icon" "$HOME/.local/share/appimages/icons/${icon_name}"
  mv "$app" ~/.local/share/applications
}

setval() {
  local file=${1?Usage: setval <file> <key> <value>}
  local key=${2?Usage: setval <file> <key> <value>}
  local val=${3?Usage: setval <file> <key> <value>}
  set -x
  sed -i -e "s|^${key}=.*|${key}=${val}|" "$file"
}

main "$@"
