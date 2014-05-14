#!/bin/bash -e
declare -r DOTFILES=".bashrc .vimrc .vim .psqlrc .gitconfig .githelpers .pylintrc .tmux.conf"
declare -r DESKTOP_DOTFILES=".gconf"
declare -a BOX_REPOS=(stevearc/pyramid_duh stevearc/dynamo3 mathcamp/dql mathcamp/flywheel mathcamp/pypicloud)

setup-install-progs() {
    sudo apt-get install -y -q \
        python-pycurl \
        python-software-properties \
        wget
}

setup-repos() {
    local list=$(ls /etc/apt/sources.list.d/chris-lea*)
    if [ ! "$list" ]; then
        sudo add-apt-repository -y ppa:chris-lea/node.js
    fi

    # docker
    #sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
}

install-common-packages() {
    sudo apt-get install -y -q ack-grep \
        autossh \
        curl \
        git \
        htop \
        ipython \
        nodejs \
        openjdk-7-jre-headless \
        openssh-client \
        openssh-server \
        python-dev \
        python-pip \
        ruby \
        rubygems \
        tmux \
        unzip \
        vim-nox \
        xsel \
        mplayer \
        tree
        # lxc-docker

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

    sudo npm install -g coffee-script uglify-js less clean-css

    sudo gem install -q mkrf
}

setup-desktop-repos() {
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - 
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
    sudo sh -c 'echo "deb http://dl.google.com/linux/talkplugin/deb/ stable main" >> /etc/apt/sources.list.d/google-talk.list'
    sudo sh -c 'echo "deb http://dl.google.com/linux/musicmanager/deb/ stable main" >> /etc/apt/sources.list.d/google-music.list'

    sudo add-apt-repository -y ppa:kevin-mehall/pithos-daily

    # dropbox
    sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
    sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ precise main" >> /etc/apt/sources.list.d/dropbox.list' 

    sudo apt-get update -qq
}

install-desktop-packages() {
  sudo apt-get install -q -y \
    # Dev tools
    ffmpeg \
    vim-gnome \
    # Desktop
    gnome \
    gnome-do \
    gthumb \
    # Misc
    desktopnova \
    flashplugin-installer \
    google-chrome-stable \
    google-talkplugin \
    google-musicmanager-beta \
    gparted \
    pithos \
    vlc
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
    if [[ ! "$mode" ]] || [[ "$mode" == "-h" ]]; then
        echo "Usage $0 [base|desktop|repos|full]"
        exit 0
    fi

    setup-install-progs
    git submodule update --init --recursive

    if [[ "$mode" == "base" ]] || [[ "$mode" == "full" ]]; then
        setup-repos
        sudo apt-get update -qq
        install-common-packages
        cp -r $DOTFILES $HOME
        sudo cp bin/* /usr/local/bin/

        # Compile command-t
        pushd $HOME/.vim/bundle/command-t/ruby/command-t
        ruby extconf.rb
        make
        popd
    fi

    if [[ "$mode" == "repos" ]] || [[ "$mode" == "full" ]]; then
        clone-repos
    fi

    if [[ "$mode" == "desktop" ]] || [[ "$mode" == "full" ]]; then
        setup-desktop-repos
        install-desktop-packages
        cp -r $DESKTOP_DOTFILES $HOME
        un-unity
    fi
}

main "$@"
