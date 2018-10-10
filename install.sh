#!/bin/bash -e
# Setup script for (X)Ubuntu 18.04
set -e
declare -r CLI_DOTFILES=".bashrc .bash_aliases .inputrc .vimrc .psqlrc .gitconfig .githelpers .tmux.conf .agignore"
declare -r BIN_EXTRA="parseargs/parseargs.sh"
declare -r DEFAULT_VIM_BUNDLES="ale ctrlp ultisnips vim-solarized8 vim-commentary vim-fugitive vim-repeat vim-snippets vim-misc vim-session neoformat vim-polyglot vim-sleuth vim-eunuch vim-vinegar vim-localrc deoplete.nvim LanguageClient-neovim space-vim-dark vim-quickerfix"
declare -r CHECKPOINT_DIR="/tmp/checkpoints"
declare -r GNOME_DOTFILES=".gconf .xbindkeysrc"
declare -r XFCE_DOTFILES=".xsessionrc"
declare -r ALL_LANGUAGES="go python js arduino clojure cs sh"
declare -r USAGE=\
"$0 [OPTIONS]
-h            Print this help menu
-d            Install dotfiles
-s            Install dotfiles as symbolic links to this repo
-c            Install command line tools
-u            Set up ufw
-l            Install language support (may be specified multiple times)
              Use 'all' to install all support for all languages.
-g            Set up a typical gnome environment
-x            Set up a typical xfce environment
-p            Install some of my custom desktop packages
-f            Force reinstallation of all programs
-v            Verbose
--languages   List all languages that are supported and exit
"
SYMBOLIC=

OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
elif [ "$OSNAME" = "Linux" ]; then
  LINUX=1
else
  WINDOWS=1
fi

command -v realpath > /dev/null 2>&1 || realpath() {
  if ! readlink -f "$1" 2> /dev/null; then
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
  fi
}
REPO=$(dirname $(realpath "$0"))

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
      [yY][eE][sS]|[yY])
        return 0
        ;;
      [nN][oO]|[nN])
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

installed() {
  # Assume everything is already installed on mac/windows
  [ ! $LINUX ] && return
  dpkg --get-selections | grep "^${1}\s*install$" >/dev/null
}

hascmd() {
  if command -v "$1" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

cp-vim-bundle() {
  local bundle=${1?Must specify a vim bundle}
  if [ $SYMBOLIC ]; then
    local dest="$HOME/.vim/bundle/$bundle"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      rm -rf "$dest"
    fi
    ln -sfT "$REPO/.vim/bundle/$bundle" "$dest"
  else
    rsync -lrp --delete --exclude .git ".vim/bundle/$bundle" "$HOME/.vim/bundle/"
  fi
}

setup-install-progs() {
  [ $WINDOWS ] && return
  if ! hascmd apt-get; then return; fi
  has-checkpoint setup-progs && return
  sudo apt-get update -qq
  sudo apt-get install -y -q \
    python-pycurl \
    software-properties-common \
    wget \
    curl
  checkpoint setup-progs
}

install-cli() {
  has-checkpoint cli && return
  if [ $WINDOWS ]; then
    pacman -Sy --noconfirm rsync tmux
  else
    sudo apt-get install -y -q \
      autossh \
      bsdmainutils \
      htop \
      inotify-tools \
      iotop \
      jq \
      lsof \
      mercurial \
      netcat \
      openssh-client \
      shellcheck \
      silversearcher-ag \
      tmux \
      tree \
      unzip \
      vim-nox \
      xsel
  fi

  checkpoint cli
}

install-cli-after() {
  [ ! $LINUX ] && return
  if ! hascmd nvim && confirm "Install Neovim?" y; then
    sudo apt-get install -y libtool autoconf automake cmake g++ gettext pkg-config \
      unzip python-dev python-pip python3 python3-dev python3-venv
    sudo apt-get install -y libtool-bin
    hascmd virtualenv || sudo pip install -q virtualenv

    [ -d ~/.envs ] || mkdir ~/.envs
    [ -d ~/.envs/py2 ] || virtualenv ~/.envs/py2
    [ -d ~/.envs/py3 ] || python3 -m venv ~/.envs/py3
    ~/.envs/py2/bin/pip install -q neovim
    ~/.envs/py3/bin/pip install -q neovim
    hascmd gem && sudo gem install neovim
    pushd /tmp
    test -d neovim || git clone https://github.com/neovim/neovim.git
    cd neovim
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    popd
    if [ ! -e ~/.nvim_python ]; then
      echo "let g:python_host_prog = \"$HOME/.envs/py2/bin/python\"" > ~/.nvim_python
      echo "let g:python3_host_prog = \"$HOME/.envs/py3/bin/python\"" >> ~/.nvim_python
    fi
    if [ ! -e ~/.config/nvim/init.vim ]; then
      mkdir -p ~/.config/nvim
      cat <<EOF > ~/.config/nvim/init.vim
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
if filereadable(expand('~/.local.vimrc'))
  source ~/.local.vimrc
endif
EOF
    fi
  fi

  if ! nc -z localhost 8377 && confirm "Install clipper?" n; then
    install-language-go
    go get github.com/wincent/clipper
    go build github.com/wincent/clipper
    sudo cp "$GOPATH/bin/clipper" /usr/local/bin
    if hascmd systemctl; then
      mkdir -p ~/.config/systemd/user
      cp "$GOPATH/src/github.com/wincent/clipper/contrib/linux/systemd-service/clipper.service" ~/.config/systemd/user
      sed -ie 's|^ExecStart.*|ExecStart=/usr/local/bin/clipper -l /var/log/clipper.log -e xsel -f "-bi"|' ~/.config/systemd/user/clipper.service
      systemctl --user daemon-reload
      systemctl --user enable clipper.service
      systemctl --user start clipper.service
    else
      sudo cp clipper.conf /etc/init
      sudo service clipper start
    fi
  fi
}

install-dotfiles() {
  mkdir -p ~/.bash.d
  if [ $SYMBOLIC ]; then
    for dotfile in $CLI_DOTFILES; do
      ln -sfT "$REPO/$dotfile" "$HOME/$dotfile"
    done
    mkdir -p ~/.vim
    for vimfile in .vim/*; do
      [ "$vimfile" = ".vim/bundle" ] && continue
      rm -rf "${HOME:?}/$vimfile"
      ln -sfT "$REPO/$vimfile" "$HOME/$vimfile"
    done
  else
    rsync -lrp $CLI_DOTFILES "$HOME"
    rsync -lrp --delete --exclude bundle --exclude .git .vim "$HOME"
  fi
  cp -r bin "$HOME"
  cp $BIN_EXTRA "$HOME/bin/"
  rsync -lrp .docker "$HOME"
  mkdir -p ~/.config
  rsync -lrp .config/nvim ~/.config/
  mkdir -p ~/.vim/bundle
  for bundle in $DEFAULT_VIM_BUNDLES; do
    cp-vim-bundle "$bundle"
  done
  if [ $WINDOWS ]; then
    # This was causing a crazy issue where quitting vim would crash Msys2
    rm -rf ~/.vim/bundle/LanguageClient-neovim
  elif [ ! -e ~/.vim/bundle/LanguageClient-neovim/bin/languageclient ]; then
    pushd ~/.vim/bundle/LanguageClient-neovim
    bash install.sh
    popd
  fi
  cp bash.d/notifier.sh ~/.bash.d/
  if [ $WINDOWS ]; then
    rsync -lrp win/ "$HOME"
  fi
}

install-security() {
  has-checkpoint security && return
  installed ufw || sudo apt-get install -y -q ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  if confirm "Allow ssh connections?" y; then
    sudo ufw allow 22/tcp
    sudo apt-get install -y -q openssh-server
  fi
  sudo ufw enable
  checkpoint security
}

install-languages() {
  local languages="$1"
  if [ -z "$languages" ]; then
    return
  fi
  if [ "$languages" == "all" ]; then
    languages="$ALL_LANGUAGES"
  fi
  setup-install-progs
  for language in $languages; do
    install-language-$language
  done
}

install-language-python() {
  cp .pylintrc "$HOME"
  cp-vim-bundle jedi-vim
  cp-vim-bundle deoplete-jedi
  if ! hascmd black; then
    python3 make_standalone.py black --pre
    mv black ~/bin
  fi
  has-checkpoint python && return
  sudo apt-get install -y -q \
    python-dev \
    python-pip \
    ipython

  sudo pip install --upgrade -q pip virtualenv autoenv
  checkpoint python
}

install-language-rust() {
  if ! rustc --version > /dev/null; then
    curl https://sh.rustup.rs -sSf | sh
    source ~/.bash_profile
  fi
  if ! hascmd racer; then
    rustup toolchain list | grep nightly || rustup toolchain add nightly
    cargo +nightly install racer
  fi
  rustup component add rls-preview rust-analysis rust-src
  # TODO: this fails for me right now
  rustup component add rustfmt-preview || :
  rustup component add rls-preview rustfmt-preview rust-analysis rust-src --toolchain nightly
  if [ ! -e ~/.bash.d/rust.sh ]; then
    echo 'export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"' > ~/.bash.d/rust.sh
  fi
  cp-vim-bundle vim-racer
}

install-language-clojure() {
  has-checkpoint clojure && return
  pushd ~/bin
  wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
  chmod a+x lein
  ./lein
  popd
  cp-vim-bundle rainbow_parentheses
  cp-vim-bundle vim-classpath
  cp-vim-bundle vim-fireplace
  checkpoint clojure
}

install-language-go() {
  if [ ! -e /usr/local/go ]; then
    pushd /tmp
    local pkg="go1.9.1.linux-amd64.tar.gz"
    if [ ! -e "$pkg" ]; then
      wget -O $pkg https://storage.googleapis.com/golang/$pkg
    fi
    sudo tar -C /usr/local -xzf $pkg
    rm -f $pkg
    popd
  fi

  PATH="/usr/local/go/bin:$PATH"
  GOPATH="$HOME/go"
}

install-language-arduino() {
  if ! hascmd arduino; then
    local default_version=$(curl https://github.com/arduino/Arduino/releases/latest | sed 's|^.*tag/\([^"]*\).*$|\1|')
    local version=$(prompt "Arduino IDE version?" "$default_version")
    local install_dir=$(prompt "Arduino IDE install dir?" /usr/local/share)
    local zipfile="arduino-${version}-linux64.tar.xz"
    pushd /tmp > /dev/null
    wget -O "$zipfile" "http://downloads.arduino.cc/$zipfile"
    tar -Jxf "$zipfile"
    sudo mv "arduino-${version}" "$install_dir"
    sudo ln -sfT "arduino-${version}" "$install_dir/arduino"
    sudo ln -sf "$install_dir/arduino/arduino" /usr/local/bin/arduino
    popd > /dev/null
  fi

  hascmd picocom || sudo apt-get install -q -y picocom
  groups | grep dialout || sudo adduser "$USER" dialout
  if [ ! -e /etc/udev/rules.d/99-USBtiny.rules ]; then
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="1781", ATTR{idProduct}=="0c9f", GROUP="dialout", MODE="0666"' | sudo tee /etc/udev/rules.d/99-USBtiny.rules
    sudo service udev restart
    sudo udevadm control --reload-rules
    sudo udevadm trigger
  fi
  cp-vim-bundle vim-arduino
}

install-language-js() {
  install-nvm
  hascmd yarn || npm install -g yarn
  hascmd prettier || npm install -g prettier
  hascmd flow || npm install -g flow-bin
  hascmd flow-language-server || npm install -g flow-language-server
  cp-vim-bundle vim-css-color
  cp-vim-bundle vim-flow-plus
  cp-vim-bundle closetag
}

install-language-sh() {
  hascmd bash-language-server && return;
  # We need npm for this
  install-nvm
  npm install -g bash-language-server
}

install-language-cs() {
  cp-vim-bundle omnisharp-vim
}


install-nvm() {
  if [ -e ~/.bash.d/nvm.sh ]; then
    source ~/.bash.d/nvm.sh || :
  fi
  nvm current && return
  local nvm_dir=$(prompt "NVM install dir:" /usr/local/nvm)
  if [ ! -d "$nvm_dir" ]; then
    pushd /tmp > /dev/null
    wget -O install.sh https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh
    chmod +x install.sh
    sudo bash -c "NVM_DIR=$nvm_dir ./install.sh"
    sudo chown -R "$USER:$USER" "$nvm_dir"
    popd > /dev/null
  fi
  source $nvm_dir/nvm.sh
  echo "source $nvm_dir/nvm.sh" > ~/.bash.d/nvm.sh
  local node_version=$(prompt "Install node version:" v10.11.0)
  nvm ls $node_version || nvm install $node_version
  nvm ls default | grep $node_version || nvm alias default $node_version
  nvm current | grep $node_version || nvm use $node_version
}

add-apt-key-google() {
  apt-key list | grep -q linux-packages-keymaster@google.com || \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
}

setup-desktop() {
  setup-install-progs
  add-apt-key-google
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  # Enable multiverse
  sudo sed -i -e 's/# \(.* multiverse$\)/\1/' /etc/apt/sources.list
  sudo apt-get update -qq

  sudo apt-get install -q -y \
    flashplugin-installer \
    google-chrome-stable \
    gparted \
    ffmpeg \
    mplayer \
    vlc

  if ! grep -q "GRUB_TIMEOUT=4" /etc/default/grub; then
    sudo sed -ie 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=4/' /etc/default/grub
    sudo update-grub
  fi

  sudo cp static/reloadaudio.sh /usr/bin/
}

setup-gnome() {
  setup-desktop
  has-checkpoint gnome && return
  [ ! $LINUX ] && return 1
  # Get rid of horrible unity scrollbars
  sudo apt-get purge -y -q \
    overlay-scrollbar \
    liboverlay-scrollbar-0.2-0 \
    liboverlay-scrollbar3-0.2-0

  sudo apt-get install -q -y \
    gnome \
    "gnome-do" \
    vim-gnome \
    xbindkeys
  cp -r $GNOME_DOTFILES $HOME
  sudo cp vim.desktop /usr/share/applications
  cp mimeapps.list ~/.local/share/applications
  checkpoint gnome
}

setup-xfce() {
  setup-desktop
  # Remap caps lock to control
  if ! grep  "XKBOPTIONS.*ctrl:nocaps" /etc/default/keyboard > /dev/null; then
    sudo sed -ie 's/XKBOPTIONS=.*/XKBOPTIONS="ctrl:nocaps"/' /etc/default/keyboard
    sudo dpkg-reconfigure keyboard-configuration
  fi

  cp -r $XFCE_DOTFILES $HOME
  mkdir -p ~/.config
  rsync -lrp .config/xfce4 ~/.config/
}

setup-custom-packages() {
  setup-install-progs
  if ! installed dropbox && confirm "Install Dropbox?" n; then
    sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
    sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ precise main" > /etc/apt/sources.list.d/dropbox.list'
    sudo apt-get update -qq
    sudo apt-get install -y -q dropbox
  fi
  if ! installed wine1.6 && confirm "Install wine?" n; then
    sudo add-apt-repository -y ppa:ubuntu-wine/ppa
    sudo apt-get install -y -q wine1.6
  fi
  if ! hascmd google-play-music-desktop-player && confirm "Install Google Play Music Desktop Player?" n; then
    wget -qO - https://gpmdp.xyz/bintray-public.key.asc | sudo apt-key add -
    echo "deb https://dl.bintray.com/marshallofsound/deb debian main" | sudo tee -a /etc/apt/sources.list.d/gpmdp.list
    sudo apt-get update -qq
    sudo apt-get install -y -q google-play-music-desktop-player
  fi
  if ! hascmd docker && confirm "Install docker?" n; then
    if [ "$(lsb_release -rs)" = '14.04' ]; then
      sudo apt-get install -yq \
        "linux-image-extra-$(uname -r)" \
        linux-image-extra-virtual
    fi
    sudo apt-get install -yq \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
    sudo apt-get update -qq
    sudo apt-get install -yq docker-ce
    confirm "Allow $USER to use docker without sudo?" y && sudo adduser "$USER" docker
    cp bash.d/bluepill.sh ~/.bash.d/
    if [ ! -L /var/lib/docker ]; then
      sudo rm -rf /var/lib/docker
      sudo ln -sfT "$HOME/.docker" /var/lib/docker
    fi
  fi
  if ! hascmd docker-compose && hascmd docker; then
    if confirm "Install docker-compose?" y; then
      local latest="$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .name)"
      sudo curl -L "https://github.com/docker/compose/releases/download/${latest}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      sudo curl -L "https://raw.githubusercontent.com/docker/compose/${latest}/contrib/completion/bash/docker-compose" -o /etc/bash_completion.d/docker-compose
    fi
  fi
  sudo apt-get install -y -q gthumb encfs
  if [[ -e ~/bin ]] && [[ ! -e ~/bin/youtube-dl ]]; then
    pushd ~/bin > /dev/null
    wget -O youtube-dl https://yt-dl.org/latest/youtube-dl
    chmod +x youtube-dl
    popd > /dev/null
  fi
}

main() {
  if [ -n "$SUDO_USER" ]; then
    echo "Do not run this script with sudo!"
    exit 1
  fi

  local languages=""
  local gnome=
  local xfce=
  local custom_packages=
  local commandline=
  local dotfiles=
  local ufw=
  while getopts "hfgxcpndsuvl:-:" opt; do
    case $opt in
      -)
        case $OPTARG in
          languages)
            echo "$ALL_LANGUAGES"
            exit 0
            ;;
          *)
            echo "$USAGE"
            exit 1
            ;;
        esac
        ;;
      p)
        custom_packages=1
        ;;
      c)
        commandline=1
        ;;
      d)
        dotfiles=1
        ;;
      g)
        gnome=1
        ;;
      x)
        xfce=1
        ;;
      u)
        ufw=1
        ;;
      s)
        SYMBOLIC=1
        ;;
      h)
        echo "$USAGE"
        exit
        ;;
      l)
        languages="$languages $OPTARG"
        ;;
      f)
        clear-checkpoints
        ;;
      v)
        set -x
        ;;
      \?)
        echo "$USAGE"
        exit 1
        ;;
    esac
  done
  shift $((OPTIND-1))
  languages=${languages# } # trim leading whitespace

  hascmd git || sudo apt-get install -y -q git
  git submodule update --init --recursive
  if [ $commandline ]; then
    install-cli
  fi
  if [ $dotfiles ]; then
    install-dotfiles
  fi
  if [ $ufw ]; then
    install-security
  fi
  install-languages "$languages"
  if [ $commandline ]; then
    install-cli-after
  fi
  if [ $gnome ]; then
    setup-gnome
  fi
  if [ $xfce ]; then
    setup-xfce
  fi
  if [ $custom_packages ]; then
    setup-custom-packages
    echo "Now use gnome-tweak-tool to bind capslock to ctrl"
    echo "And use dconf editor org>gnome>desktop>wm to add keyboard shortcuts"
    echo "Maybe install some proprietary graphics drivers? (e.g. nvidia-331)"
  fi
  echo "Done"
}

main "$@"
