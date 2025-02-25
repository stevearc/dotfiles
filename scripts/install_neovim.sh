#!/bin/bash
set -e -o pipefail

OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
fi
ARCH="$(uname -p)"

main() {
  local usage="$0 [OPTS] [VERSION]

Options:
  -l, --list    List available versions
  -s, --silent  Quiet download
  -d            Destination dir (default ~/.local/bin)
  -n [NAME]     Binary name (default nvim)
"
  LIST=
  SILENT=
  DEST="$HOME/.local/bin"
  NAME='nvim'
  unset OPTIND
  while getopts "hsln:d:-:" opt; do
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
    d)
      DEST="$OPTARG"
      ;;
    n)
      NAME="$OPTARG"
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
  shift $((OPTIND - 1))
  VERSION="$1"
  shift || :
  if [ -n "$1" ]; then
    echo "Put options before version number"
    exit 1
  fi

  if [ -n "$LIST" ]; then
    curl -s https://api.github.com/repos/neovim/neovim/releases | jq -r ".[].tag_name"
  elif [ -n "$VERSION" ]; then
    mkdir -p "$DEST"
    echo "Installing NVIM $VERSION"
    if [ -n "$MAC" ]; then
      _install_mac "$DEST"
    else
      _install_linux "$DEST"
    fi
    echo -n "Installed "
    "$DEST/$NAME" --version | head -n 1
  else
    echo "Usage: $usage"
    return 1
  fi
}

_install_mac() {
  rm -rf .nvim-osx64
  [ -n "$SILENT" ] && silent="-s"
  local suffix="$(_get_dist_suffix)"
  curl $silent -LO https://github.com/neovim/neovim/releases/download/nightly/nvim${suffix}.tar.gz
  tar xzf nvim-macos.tar.gz
  rm -f nvim-macos.tar.gz
  mv nvim-osx64 .nvim-osx64
  mkdir -p "$DEST"
  rm -f "$DEST/$NAME"
  ln -s ~/.nvim-osx64/bin/nvim "$DEST/$NAME"
}

_install_linux() {
  [ -n "$SILENT" ] && silent="-s"

  local suffix="$(_get_dist_suffix)"
  curl $silent -L "https://github.com/neovim/neovim/releases/download/$VERSION/nvim${suffix}.appimage" -o nvim.appimage
  chmod +x nvim.appimage
  mkdir -p "$DEST"
  if ! ./nvim.appimage --headless +qall >/dev/null 2>&1; then
    mkdir -p ~/.appimages
    mv nvim.appimage "$HOME/.appimages/$NAME.appimage"
    pushd ~/.appimages
    "./$NAME.appimage" --appimage-extract >/dev/null
    rm -rf "$NAME-appimage"
    mv squashfs-root "$NAME-appimage"
    ln -s -f "$HOME/.appimages/$NAME-appimage/AppRun" "$DEST/$NAME"
    rm "$NAME.appimage"
    popd
  else
    mv nvim.appimage "$DEST/$NAME"
  fi
}

_get_dist_suffix() {
  # If the version is less than v0.10.4, use the old naming scheme
  if [[ "$VERSION" =~ "^v" ]] && ! printf 'v0.10.4\n%s\n' "$VERSION" | sort -V -C; then
    if [ -n "$MAC" ]; then
      echo "-macos"
    fi
    return
  fi

  local suffix=""
  if [ -n "$MAC" ]; then
    suffix="-macos"
  else
    suffix="-linux"
  fi

  if [ "$ARCH" = "aarch64" ]; then
    echo "$suffix-arm64"
  else
    echo "$suffix-x86_64"
  fi
}

main "$@"
