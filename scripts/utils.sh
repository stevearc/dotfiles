#!/bin/bash
declare -r CHECKPOINT_DIR="$HERE/.checkpoints"
OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  export MAC=1
elif [ "$OSNAME" = "Linux" ]; then
  export LINUX=1
  if grep -q Microsoft /proc/version 2>/dev/null; then
    export WSL=1
    export C_DRIVE="/mnt/c"
  fi
else
  export WINDOWS=1
fi

hascmd() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

if hascmd apt-get; then
  export UBUNTU=1
elif hascmd pamac; then
  export MANJARO=1
elif hascmd pacman; then
  export ARCHOS=1
fi

command -v realpath >/dev/null 2>&1 || realpath() {
  if ! readlink -f "$1" 2>/dev/null; then
    [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
  fi
}

prompt() {
  # $1 [str] - Prompt string
  # $2 (optional) [str] - The default return value if user just hits enter
  local text="$1 "
  local default="$2"
  if [ -n "$default" ]; then
    text="${text}[$default] "
  fi
  while true; do
    read -r -p "$text" response
    if [ -n "$response" ]; then
      echo "$response"
      return 0
    elif [ -n "$default" ]; then
      echo "$default"
      return 0
    fi
  done
}

link() {
  local source="${1?missing source}"
  local dest="${2?missing dest}"
  if [ $LINUX ]; then
    ln -sfT "$source" "$dest"
  elif [ $MAC ]; then
    if [ -e "$dest" ]; then
      rm -rf "$dest"
    fi
    ln -s "$source" "$dest"
  fi
}

confirm() {
  # $1 (optional) [str] - Prompt string
  # $2 (optional) [y|n] - The default return value if user just hits enter
  local prompt="${1-Are you sure?}"
  local default="$2"
  case $default in
    [yY])
      prompt="$prompt [Y/n] "
      ;;
    [nN])
      prompt="$prompt [y/N] "
      ;;
    *)
      prompt="$prompt [y/n] "
      ;;
  esac
  while true; do
    read -r -p "$prompt" response
    case $response in
      [yY][eE][sS] | [yY])
        return 0
        ;;
      [nN][oO] | [nN])
        return 1
        ;;
      *)
        if [ -z "$response" ]; then
          case $default in
            [yY])
              return 0
              ;;
            [nN])
              return 1
              ;;
          esac
        fi
        ;;
    esac
  done
}

checkpoint() {
  # Create a checkpoint
  # $1 [str] - Unique key for the checkpoint
  mkdir -p "$CHECKPOINT_DIR"
  touch "$CHECKPOINT_DIR/${1?checkpoint must have an argument}"
}

has-checkpoint() {
  # Check if a checkpoint has been reached
  # $1 [str] - Unique key for the checkpoint
  test -e "$CHECKPOINT_DIR/${1?has-checkpoint must have an argument}"
}

clear-checkpoints() {
  # Remove all checkpoints
  rm -rf "$CHECKPOINT_DIR"
}

mirror() {
  local src="${1?Must specify source}"
  local dest="${2?Must specify dest}"
  local symbolic="${3?Use 1 for symbolic link or empty string to copy files}"
  local parent
  parent="$(dirname "$dest")"
  mkdir -p "$parent"
  if [ -n "$symbolic" ]; then
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      rm -rf "$dest"
    fi
    link "$src" "$dest"
  else
    if [ -d "$src" ]; then
      rsync -lrp --delete --exclude .git "$src" "$dest"
    else
      cp "$src" "$dest"
    fi
  fi
}
