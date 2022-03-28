#!/bin/bash
set -e

post-install-neovim() {
  [ -d ~/.envs ] || mkdir ~/.envs
  [ -d ~/.envs/py3 ] || python3 -m venv ~/.envs/py3
  ~/.envs/py3/bin/pip install -q wheel
  ~/.envs/py3/bin/pip install -q pynvim

  if ! hascmd nvr; then
    mkdir -p ~/.local/bin
    pushd ~/.local/bin
    "$HERE/scripts/make_standalone.py" -s nvr neovim-remote
    popd
  fi
  nvim --headless +UpdateRemotePlugins +TSUpdateSync -c 'call firenvim#install(0)' +qall >/dev/null
}

