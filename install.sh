#!/bin/bash -e
set -e
declare -r CLI_DOTFILES=".bashrc .bash_aliases .inputrc .vimrc .psqlrc .gitconfig .githelpers .tmux.conf bin .agignore .docker"
declare -r BIN_EXTRA="parseargs/parseargs.sh"
declare -r DEFAULT_VIM_BUNDLES="ale ctrlp ultisnips vim-colors-solarized vim-commentary vim-easymotion vim-fugitive vim-repeat vim-snippets vim-misc vim-session neoformat vim-polyglot vim-sleuth vim-eunuch vim-vinegar"
declare -r CHECKPOINT_DIR="/tmp/checkpoints"
declare -r GNOME_DOTFILES=".gconf .xbindkeysrc"
declare -r ALL_LANGUAGES="go python js arduino clojure"
declare -r USAGE=\
"$0 [OPTIONS]
-h            Print this help menu
-d            Install dotfiles
-c            Install command line tools
-s            Set up security (ufw)
-l            Install language support (may be specified multiple times)
              Use 'all' to install all support for all languages.
-g            Set up a typical gnome environment
-p            Install some of my custom desktop packages
-f            Force reinstallation of all programs
--languages   List all languages that are supported and exit
"

OSNAME=$(uname -s)
if [ "$OSNAME" = "Darwin" ]; then
  MAC=1
else
  LINUX=1
fi

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
  dpkg --get-selections | grep install | grep "$1" >/dev/null
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
  if [ ! -e ~/.vim/bundle/$bundle ]; then
    cp -r .vim/bundle/$bundle ~/.vim/bundle/$bundle
  fi
}

setup-install-progs() {
  has-checkpoint setup-progs && return
  sudo apt-get update -qq
  sudo apt-get install -y -q \
    python-pycurl \
    python-software-properties \
    software-properties-common \
    wget \
    curl
  checkpoint setup-progs
}

install-cli() {
  has-checkpoint cli && return
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

  checkpoint cli
}

install-cli-after() {
  if ! hascmd nvim && confirm "Install Neovim?" n; then
    sudo apt-get install -y libtool autoconf automake cmake g++ pkg-config \
      unzip python-dev python-pip python3 python3-dev python3-pip ruby ruby-dev
    sudo apt-get install -y libtool-bin || : # Ubuntu 16.04
    pip freeze | grep neovim > /dev/null || sudo pip install neovim
    pip3 freeze | grep neovim > /dev/null || sudo pip3 install neovim
    sudo gem install neovim
    pushd /tmp
    test -d neovim || git clone https://github.com/neovim/neovim.git
    cd neovim
    make CMAKE_BUILD_TYPE=Release
    sudo make install
    popd
    if [ ! -e ~/.nvim_python ]; then
      hascmd python && echo "let g:python_host_prog=\"$(command -v python)\"" > ~/.nvim_python
      hascmd python3 && echo "let g:python3_host_prog=\"$(command -v python3)\"" >> ~/.nvim_python
    fi
    if [ ! -e ~/.config/nvim/init.vim ]; then
      mkdir -p ~/.config/nvim
      cat <<EOF > ~/.config/nvim/init.vim
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
EOF
    fi
  fi

  if ! nc -z localhost 8377 && confirm "Install clipper?" n; then
    install-language-go
    go get github.com/wincent/clipper
    go build github.com/wincent/clipper
    sudo cp $GOPATH/bin/clipper /usr/local/bin
    if hascmd systemctl; then
      mkdir -p ~/.config/systemd/user
      cp $GOPATH/src/github.com/wincent/clipper/contrib/linux/systemd-service/clipper.service ~/.config/systemd/user
      sed -ie 's|^ExecStart.*|ExecStart=/usr/local/bin/clipper -l /var/log/clipper.log -e xsel -f "-bi"|' ~/.config/systemd/user/clipper.service
      systemctl --user daemon-reload
      systemctl --user enable clipper.service
      systemctl --user start clipper.service
    else
      sudo cp clipper.conf /etc/init
      sudo service clipper start
    fi
    echo "You may need to create a startup application that runs 'xhost +SI:localuser:root'"
  fi
}

install-dotfiles() {
  has-checkpoint dotfiles && return
  mkdir -p ~/.bash.d
  cp -r $CLI_DOTFILES $HOME
  cp $BIN_EXTRA $HOME/bin/
  rsync -lrp --exclude bundle --exclude .git .vim $HOME
  rsync -lrp .config $HOME
  mkdir -p ~/.vim/bundle
  for bundle in $DEFAULT_VIM_BUNDLES; do
    cp-vim-bundle $bundle
  done
  cp bash.d/notifier.sh ~/.bash.d/
  checkpoint dotfiles
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
  has-checkpoint python && return
  sudo apt-get install -y -q \
    python-dev \
    python-pip \
    ipython

  sudo pip install -q virtualenv autoenv
  cp .pylintrc $HOME
  cp-vim-bundle python-mode
  checkpoint python
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
  has-checkpoint arduino && return

  if ! hascmd arduino; then
    local default_version=$(curl https://github.com/arduino/Arduino/releases/latest | sed 's|^.*tag/\([^"]*\).*$|\1|')
    local version=$(prompt "Arduino IDE version?" $default_version)
    local install_dir=$(prompt "Arduino IDE install dir?" /usr/local/share)
    local zipfile="arduino-${version}-linux64.tar.xz"
    pushd /tmp > /dev/null
    wget -O $zipfile http://downloads.arduino.cc/$zipfile
    tar -Jxf $zipfile
    sudo mv arduino-${version} $install_dir
    sudo ln -s arduino-${version} $install_dir/arduino
    sudo ln -s $install_dir/arduino/arduino /usr/local/bin
    popd > /dev/null
  fi

  sudo apt-get install -q -y picocom
  sudo adduser $USER dialout
  cp-vim-bundle vim-arduino
  checkpoint arduino
}

install-language-js() {
  has-checkpoint javascript && return
  install-nvm
  npm install -g yarn prettier flow-bin
  cp-vim-bundle vim-css-color
  cp-vim-bundle vim-flow-plus
  cp-vim-bundle closetag
  checkpoint javascript
}

install-nvm() {
  nvm current && return
  local nvm_dir=$(prompt "NVM install dir:" /usr/local/nvm)
  if [ ! -d $nvm_dir ]; then
    pushd /tmp > /dev/null
    wget -O install.sh https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh
    chmod +x install.sh
    sudo bash -c "NVM_DIR=$nvm_dir ./install.sh"
    sudo chown -R $USER:$USER $nvm_dir
    popd > /dev/null
  fi
  source $nvm_dir/nvm.sh
  echo "source $nvm_dir/nvm.sh" > ~/.bash.d/nvm.sh
  local node_version=$(prompt "Install node version:" v8.7.0)
  nvm ls $node_version || nvm install $node_version
  nvm ls default || nvm alias default $node_version
  nvm use $node_version
}

add-apt-key-google() {
  apt-key list | grep linux-packages-keymaster@google.com > /dev/null || \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
}

setup-gnome() {
  has-checkpoint gnome && return
  setup-install-progs
  # Get rid of horrible unity scrollbars
  sudo apt-get purge -y -q \
    overlay-scrollbar \
    liboverlay-scrollbar-0.2-0 \
    liboverlay-scrollbar3-0.2-0

  add-apt-key-google
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  # Enable multiverse
  sudo sed -i -e 's/# \(.* multiverse$\)/\1/' /etc/apt/sources.list
  sudo apt-get update -qq
  sudo apt-get install -q -y \
    gnome \
    "gnome-do" \
    vim-gnome \
    flashplugin-installer \
    google-chrome-stable \
    gparted \
    libav-tools \
    mplayer \
    vlc \
    xbindkeys
  cp -r $GNOME_DOTFILES $HOME
  sudo cp vim.desktop /usr/share/applications
  cp mimeapps.list ~/.local/share/applications
  checkpoint gnome
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
  if ! hascmd docker && confirm "Install docker?" n; then
    if [ "$(lsb_release -rs)" = '14.04' ]; then
      sudo apt-get install -y \
        "linux-image-extra-$(uname -r)" \
        linux-image-extra-virtual
    fi
    sudo apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
     "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    confirm "Allow $USER to use docker without sudo?" y && sudo adduser "$USER" docker
    cp bash.d/bluepill.sh ~/.bash.d/
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
  local custom_packages=
  local commandline=
  local dotfiles=
  local secure=
  while getopts "hfgcpndsl:-:" opt; do
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
      s)
        secure=1
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
      \?)
        echo "$USAGE"
        exit 1
        ;;
    esac
  done
  shift $((OPTIND-1))
  languages=${languages# } # trim leading whitespace

  installed git || sudo apt-get install -y -q git
  git submodule update --init --recursive
  if [ $commandline ]; then
    install-cli
  fi
  if [ $dotfiles ]; then
    install-dotfiles
  fi
  if [ $secure ]; then
    install-security
  fi
  install-languages "$languages"
  if [ $commandline ]; then
    install-cli-after
  fi
  if [ $gnome ]; then
    setup-gnome
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
