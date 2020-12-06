#!/bin/bash
set -e -o pipefail

OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
fi

main(){
  local usage="$0 [VERSION]

Options:
  -l, --list    List available versions
  -s, --silent  Quiet download
"
  LIST=
  SILENT=
  unset OPTIND
  while getopts ":hsl-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          help)
            echo "$usage"
            return 0
            ;;
          list)
            LIST=1
            ;;
          silent)
            SILENT=1
            ;;
          *)
            echo "$usage"
            return 1
            ;;
        esac
        ;;
      h)
        echo "$usage"
        return 0
        ;;
      s)
        SILENT=1
        ;;
      l)
        LIST=1
        ;;
      \?)
        echo "$usage"
        return 1
        ;;
    esac
  done
  shift $((OPTIND-1))
  VERSION="$1"

  if [ -n "$LIST" ]; then
    curl -s https://api.github.com/repos/neovim/neovim/releases | jq ".[].tag_name" | tr -d '"'
  elif [ -n "$VERSION" ]; then
    echo "Installing NVIM $VERSION"
    if [ -n "$MAC" ]; then
      _install_mac
    else
      _install_linux
    fi
    ~/bin/nvim --headless +UpdateRemotePlugins +qall > /dev/null
    echo -n "Installed "
    ~/bin/nvim --version | head -n 1
  else
    echo "Usage: $usage"
    return 1
  fi
}

_install_mac() {
  rm -rf .nvim-osx64
  [ -n "$SILENT" ] && silent="-s"
  curl $silent -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz
  tar xzf nvim-macos.tar.gz
  rm -f nvim-macos.tar.gz
  mv nvim-osx64 .nvim-osx64
  rm -f ~/bin/nvim
  ln -s ~/.nvim-osx64/bin/nvim ~/bin/nvim
}

_install_linux() {
  [ -n "$SILENT" ] && silent="-s"
  curl $silent -L "https://github.com/neovim/neovim/releases/download/$VERSION/nvim.appimage" -o nvim.appimage
  chmod +x nvim.appimage
  if ! ./nvim.appimage --headless +qall > /dev/null 2>&1; then
    mkdir -p ~/.appimages
    mv nvim.appimage ~/.appimages
    pushd ~/.appimages
    ./nvim.appimage --appimage-extract > /dev/null
    rm -rf nvim-appimage
    mv squashfs-root nvim-appimage
    ln -s -f ~/.appimages/nvim-appimage/AppRun ~/bin/nvim
    rm nvim.appimage
    popd
  else
    mv nvim.appimage ~/bin/nvim
  fi
}

main "$@"
