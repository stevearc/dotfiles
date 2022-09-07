#!/bin/bash
export NVENV

_nvenv-list() {
  ls ~/.local/share/nvenv 2>/dev/null || echo "No nvenvs available"
  if [ -n "$NVENV" ]; then
    echo "Active: $NVENV"
  fi
}

_nvenv-deactivate() {
  export NVENV=
  unalias nvim 2>/dev/null
  alias vim='nvim'
}

_nvenv-activate() {
  local name="${1?Usage: nvenv activate <name>}"
  if [ ! -e "$HOME/.local/share/nvenv/$name" ]; then
    echo "No nvenv $name found"
    return
  fi
  unalias vim 2>/dev/null
  unalias nvim 2>/dev/null
  alias nvim='_nvenv-nvim'
  alias vim='_nvenv-nvim'
  export NVENV="$name"
}

_nvenv-create() {
  local name=${1?Usage: nvenv create <name> [<binary_name>]}
  local bin_name=${2-nvim}
  mkdir -p "$HOME/.local/share/nvenv/$name"
  echo "$bin_name" >"$HOME/.local/share/nvenv/$name/bin_name"
}

_nvenv-cd() {
  local name="${1?Usage: nvenv cd <name>}"
  cd "$HOME/.local/share/nvenv/$name"
}

_nvenv-nvim() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/config"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/data"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/state"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/run"
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/cache"
  local bin_name
  bin_name="$(cat "$HOME/.local/share/nvenv/$NVENV/bin_name")"
  XDG_CONFIG_HOME="$HOME/.local/share/nvenv/$NVENV/config" \
    XDG_DATA_HOME="$HOME/.local/share/nvenv/$NVENV/data" \
    XDG_STATE_HOME="$HOME/.local/share/nvenv/$NVENV/state" \
    XDG_RUNTIME_DIR="$HOME/.local/share/nvenv/$NVENV/run" \
    XDG_CACHE_HOME="$HOME/.local/share/nvenv/$NVENV/cache" \
    "$bin_name" "$@"
}

# Install a plugin
_nvenv-install() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  local repo="${1?Usage: nvenv install [REPO]}"
  local name="${1##*/}"
  git clone "$repo" "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$name/start/$name"
}

# Link a plugin from the default nvim install
_nvenv-link() {
  if [ -z "$NVENV" ]; then
    echo "Must activate nvenv first"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/"
  while [ -n "$1" ]; do
    rm -f "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$1"
    ln -s "$HOME/.local/share/nvim/site/pack/$1" "$HOME/.local/share/nvenv/$NVENV/data/nvim/site/pack/$1"
    shift
  done
}

# Edit the init file for a nvenv
_nvenv-edit() {
  local name="${1-$NVENV}"
  if [ -z "$name" ]; then
    echo "Usage nvenv edit <name>"
    return
  fi
  mkdir -p "$HOME/.local/share/nvenv/$name/config/nvim"
  'nvim' "$HOME/.local/share/nvenv/$name/config/nvim/init.lua"
}

# Clone a nvenv
_nvenv-clone() {
  local source="${1?Usage: nvenv clone <source> <target>}"
  local dest="${2?Usage: nvenv clone <source> <target>}"
  local src_data
  local src_config
  local bin_name
  if [ "$source" = "default" ] || [ "$source" = "nvim" ]; then
    src_data="$HOME/.local/share/nvim"
    src_config="$HOME/.config/nvim"
    bin_name="nvim"
  else
    src_data="$HOME/.local/share/nvenv/$source/data/nvim"
    src_config="$HOME/.local/share/nvenv/$source/config/nvim"
    bin_name="$(cat "$HOME/.local/share/nvenv/$source/bin_name")"
  fi
  src_site="$src_data/site/pack"
  _nvenv-create "$dest" "$bin_name"
  mkdir -p "$HOME/.local/share/nvenv/$dest/data/nvim/site/pack"
  for plugpath in "$src_site"/*; do
    local plugin
    plugin="$(basename "$plugpath")"
    ln -s "$plugpath" "$HOME/.local/share/nvenv/$dest/data/nvim/site/pack/$plugin"
  done
  mkdir -p "$HOME/.local/share/nvenv/$dest/config/nvim"
  rsync -rLptgoD "$src_config" "$HOME/.local/share/nvenv/$dest/config/"
}

nvenv() {
  local usage="nvenv [create|list|activate|deactivate|install|link|edit]"
  local cmd="$1"
  if [ -z "$cmd" ]; then
    echo "$usage"
    return
  fi
  shift
  "_nvenv-$cmd" "$@"
}
