#!/bin/bash -e
declare -r DOTFILES=".bashrc .vimrc .vim .psqlrc .gitconfig .githelpers .pylintrc .tmux.conf .bin .agignore .tmuxinator"
declare -r DESKTOP_DOTFILES=".gconf .xbindkeysrc"
declare -a BOX_REPOS=(stevearc/pyramid_duh stevearc/dynamo3 mathcamp/dql mathcamp/flywheel mathcamp/pypicloud)
declare -r NODE_VERSION="0.8.28"
declare -r NVM_DIR="/usr/local/nvm"
declare -r DESCRIPTION="bare-desktop: Set up gnome and typical utilities
dev:          Set up common dev tools
desktop:      Set up my custom desktop programs
repos:        Clone my open source repos for development
full:         Full custom desktop setup
"

setup-install-progs() {
    sudo apt-get install -y -q \
        python-pycurl \
        python-software-properties \
        wget \
        curl
}

install-common-packages() {
    install-nvm
    sudo apt-get install -y -q silversearcher-ag \
        autossh \
        git \
        mercurial \
        htop \
        iotop \
        ipython \
        openssh-client \
        openssh-server \
        python-dev \
        python-pip \
        tmux \
        unzip \
        vim-nox \
        xsel \
        mplayer \
        tree

    if [ ! -e /usr/local/go ]; then
        pushd /tmp
        local pkg="go1.2.2.linux-amd64.tar.gz"
        if [ ! -e "$pkg" ]; then
            wget https://storage.googleapis.com/golang/$pkg
        fi
        sudo tar -C /usr/local -xzf $pkg
        rm -f $pkg
        popd
    fi

    sudo pip install -q virtualenv autoenv

    sudo npm install -g coffee-script uglify-js less clean-css coffee-react

    sudo gem install -q tmuxinator
}

install-nvm() {
  pushd /tmp
  rm -f install.sh
  wget https://raw.githubusercontent.com/creationix/nvm/v0.25.1/install.sh
  sudo bash -c "NVM_DIR=$NVM_DIR install.sh"
  source $NVM_DIR/nvm.sh
  nvm install $NODE_VERSION
  nvm alias default $NODE_VERSION
  nvm use default
  popd
}

setup-desktop-repos() {
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo sh -c 'echo "deb http://dl.google.com/linux/talkplugin/deb/ stable main" >> /etc/apt/sources.list.d/google-talk.list'
    sudo sh -c 'echo "deb http://dl.google.com/linux/musicmanager/deb/ stable main" >> /etc/apt/sources.list.d/google-music.list'
    sudo apt-get update -qq
}

setup-custom-desktop-repos() {
    #sudo add-apt-repository -y ppa:kevin-mehall/pithos-daily
    sudo add-apt-repository -y ppa:ubuntu-wine/ppa

    # dropbox
    sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
    sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ precise main" >> /etc/apt/sources.list.d/dropbox.list' 

    sudo apt-get update -qq
}

install-desktop-packages() {
  sudo apt-get install -q -y \
    gnome \
    "gnome-do" \
    flashplugin-installer \
    google-chrome-stable \
    gparted \
    xbindkeys
}

install-custom-desktop-packages() {
  sudo apt-get install -q -y \
    vim-gnome \
    gthumb \
    dropbox \
    encfs \
    google-talkplugin \
    google-musicmanager-beta \
    vlc \
    wine1.6
  if [ -e ~/.bin ]; then
      pushd ~/.bin
      wget https://yt-dl.org/latest/youtube-dl
      chmod +x youtube-dl
      popd
  fi
}

un-unity() {
    sudo apt-get purge -y \
        overlay-scrollbar \
        liboverlay-scrollbar-0.2-0 \
        liboverlay-scrollbar3-0.2-0
}

clone-repos() {
    pushd $HOME
    mkdir -p ws
    cd ws
    wget https://raw.github.com/mathcamp/devbox/master/devbox/unbox.py

    for repo in ${BOX_REPOS[@]}; do
        python unbox.py git@github.com:$repo
    done

    rm unbox.py
    popd
}

main() {
    local mode=$1
    if [[ ! "$mode" ]] || [[ "$mode" == "-h" ]] || [[ "$mode" == "help" ]]; then
        echo "Usage $0 [help|bare-desktop|dev|desktop|repos|full]"
        if [[ "$mode" == "-h" ]] || [[ "$mode" == "help" ]]; then
            echo -e "$DESCRIPTION"
        fi
        exit 0
    fi

    setup-install-progs
    git submodule update --init --recursive

    if [[ "$mode" == "dev" ]] || [[ "$mode" == "full" ]]; then
        sudo apt-get update -qq
        install-common-packages
        cp -r $DOTFILES $HOME
    fi

    if [[ "$mode" == "repos" ]] || [[ "$mode" == "full" ]]; then
        clone-repos
    fi

    if [[ "$mode" == "bare-desktop" ]] ||
       [[ "$mode" == "desktop" ]] ||
       [[ "$mode" == "full" ]]; then
        setup-desktop-repos
        install-desktop-packages
        cp -r $DESKTOP_DOTFILES $HOME
        sudo cp vim.desktop /usr/share/applications
        cp mimeapps.list ~/.local/share/applications
        un-unity
    fi

    if [[ "$mode" == "desktop" ]] || [[ "$mode" == "full" ]]; then
        setup-custom-desktop-repos
        install-custom-desktop-packages
        echo "Now use gnome-tweak-tool to bind capslock to ctrl"
        echo "And use dconf editor org>gnome>desktop>wm to add keyboard shortcuts"
        echo "Maybe install some proprietary graphics drivers? (e.g. nvidia-331)"
    fi
}

main "$@"
