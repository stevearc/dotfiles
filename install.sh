#!/bin/bash -e
# Setup script for (X)Ubuntu 20.04
#
# If using WSL, first do:
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
# wsl --set-default-version 2
# Start-Process -FilePath https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q
# Start-Process -FilePath https://www.microsoft.com/en-gb/p/windows-terminal/9n0dx20hk701
# Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
set -e
declare -r CLI_DOTFILES=".bashrc .bash_aliases .inputrc .vimrc .psqlrc .gitconfig .githelpers .tmux.conf .agignore"
declare -r DEFAULT_VIM_BUNDLES="completion-nvim ultisnips vim-solarized8 vim-commentary vim-fugitive vim-repeat vim-snippets vim-misc vim-session neoformat vim-polyglot vim-eunuch deoplete.nvim nvim-lspconfig deoplete-lsp vim-surround editorconfig-vim nvim-colorizer.lua nvim-treesitter nvim-treesitter-context plenary.nvim popup.nvim vim-endwise vim-autoswap defx.nvim aerial.nvim targets.vim telescope.nvim quickfix-reflector.vim vim-vsnip vim-vsnip-integ nvim-compe"
declare -r CHECKPOINT_DIR="/tmp/checkpoints"
declare -r XFCE_DOTFILES=".xsessionrc"
declare -r ALL_LANGUAGES="go python js arduino clojure cs rust"
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
  if grep -q Microsoft /proc/version 2> /dev/null; then
    WSL=1
    C_DRIVE="/mnt/c"
  fi
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

winsudo() {
  if [ -z "$WSL" ]; then
    echo "Cannot use winsudo if not in WSL"
    return
  fi
  powershell.exe -command "start-process -verb runas powershell" "'-command $*'"
}

cp-vim-bundle() {
  local bundle=${1?Must specify a vim bundle}
  if [ $SYMBOLIC ]; then
    local dest="$HOME/.vim/bundle/$bundle"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      rm -rf "$dest"
    fi
    link "$REPO/.vim/bundle/$bundle" "$dest"
  else
    rsync -lrp --delete --exclude .git ".vim/bundle/$bundle" "$HOME/.vim/bundle/"
  fi
}

setup-install-progs() {
  [ $WINDOWS ] && return
  has-checkpoint setup-progs && return
  if hascmd apt-get; then
    sudo apt-get update -qq
    sudo apt-get install -y -q \
      python-pycurl \
      software-properties-common \
      wget \
      curl
  elif [ $MAC ]; then
    hascmd brew || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  checkpoint setup-progs
}

install-cli() {
  has-checkpoint cli && return
  if [ $WINDOWS ]; then
    pacman -Sy --noconfirm rsync tmux
  elif [ $MAC ]; then
    hascmd tmux || install_tmux.sh
  else
    sudo apt-get install -y -q \
      autossh \
      bsdmainutils \
      direnv \
      htop \
      inotify-tools \
      iotop \
      jq \
      lsof \
      mercurial \
      netcat \
      openssh-client \
      rsync \
      shellcheck \
      ripgrep \
      tmux \
      tree \
      unzip \
      vim-nox \
      wmctrl \
      xsel
  fi

  checkpoint cli
}

install-cli-after() {
  [ ! $LINUX ] && [ ! $MAC ] && return
  if ! hascmd nvim; then
    if confirm "From github appimage?" y; then
      local version
      install_neovim.sh --list
      version=$(prompt "Version?" nightly)
      install_neovim.sh "$version"
    elif confirm "From source?" n; then
      sudo apt-get install -y libtool autoconf automake cmake g++ gettext pkg-config \
        unzip python3 python3-dev python3-venv ruby-dev
      sudo apt-get install -y libtool-bin
      pushd /tmp
      test -d neovim || git clone https://github.com/neovim/neovim.git
      cd neovim
      make CMAKE_BUILD_TYPE=Release
      sudo make install
      popd
    else
      sudo apt-get install -y neovim
    fi
  fi

  # Let's just always do the things for neovim
  [ -d ~/.envs ] || mkdir ~/.envs
  [ -d ~/.envs/py3 ] || python3 -m venv ~/.envs/py3
  ~/.envs/py3/bin/pip install -q wheel pynvim

  if [ ! -e ~/.nvim_python ]; then
    echo "let g:python3_host_prog = \"$HOME/.envs/py3/bin/python\"" >> ~/.nvim_python
  fi

  # Probably don't care about clipper anymore
  # if ! nc -z localhost 8377 && confirm "Install clipper?" n; then
  #   install-language-go
  #   go get github.com/wincent/clipper
  #   go build github.com/wincent/clipper
  #   sudo cp "$GOPATH/bin/clipper" /usr/local/bin
  #   if hascmd systemctl; then
  #     mkdir -p ~/.config/systemd/user
  #     cp "$GOPATH/src/github.com/wincent/clipper/contrib/linux/systemd-service/clipper.service" ~/.config/systemd/user
  #     sed -ie 's|^ExecStart.*|ExecStart=/usr/local/bin/clipper -l /var/log/clipper.log -e xsel -f "-bi"|' ~/.config/systemd/user/clipper.service
  #     systemctl --user daemon-reload
  #     systemctl --user enable clipper.service
  #     systemctl --user start clipper.service
  #   else
  #     sudo cp clipper.conf /etc/init
  #     sudo service clipper start
  #   fi
  # fi
}

install-dotfiles() {
  if [ $SYMBOLIC ]; then
    for dotfile in $CLI_DOTFILES; do
      link "$REPO/$dotfile" "$HOME/$dotfile"
    done
    mkdir -p ~/.vim
    for vimfile in .vim/*; do
      [ "$vimfile" = ".vim/bundle" ] && continue
      rm -rf "${HOME:?}/$vimfile"
      link "$REPO/$vimfile" "$HOME/$vimfile"
    done
  else
    rsync -lrp $CLI_DOTFILES "$HOME"
    rsync -lrp --delete --exclude bundle --exclude .git .vim "$HOME"
  fi

  mkdir -p ~/bin
  if [ $SYMBOLIC ]; then
    for executable in bin/*; do
      link "$REPO/$executable" "$HOME/$executable"
    done
    link "$REPO/parseargs/parseargs.sh" "$HOME/bin/parseargs.sh"
  else
    rsync -lrp bin "$HOME/bin"
    cp "$REPO/parseargs/parseargs.sh" "$HOME/bin/"
  fi

  rsync -lrp .docker "$HOME"
  mkdir -p ~/.config
  rsync -lrp .config/nvim ~/.config/
  mkdir -p ~/.vim/bundle
  for bundle in $DEFAULT_VIM_BUNDLES; do
    cp-vim-bundle "$bundle"
  done

  mkdir -p ~/.bash.d
  if [ $SYMBOLIC ]; then
    for file in bash.d/*; do
      link "$REPO/$file" "$HOME/.$file"
    done
  else
    rsync -lrp bash.d "$HOME/.bash.d"
  fi

  if [ $WINDOWS ]; then
    rsync -lrp win/ "$HOME"
  fi
  if [ -e ~/.bash_profile ]; then
    grep "source ~/.bashrc" ~/.bash_profile > /dev/null 2>&1 || echo "source ~/.bashrc" >> ~/.bash_profile
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

install-dotnet() {
  if hascmd dotnet || ! hascmd apt-get; then
    return
  fi
  # From https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
  pushd /tmp
  wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb

  sudo apt-get update
  sudo apt-get install -y apt-transport-https
  sudo apt-get update
  sudo apt-get install -y dotnet-sdk-3.1
  popd
}

install-language-python() {
  cp .pylintrc "$HOME"
  hascmd apt-get && sudo apt-get install -y -q \
    python3 \
    python3-distutils \
    python3-venv
  if ! hascmd black; then
    python3 make_standalone.py black
    mv black ~/bin
  fi
  if ! hascmd pylint; then
    python3 make_standalone.py pylint
    mv pylint ~/bin
  fi
  if ! hascmd pycodestyle; then
    python3 make_standalone.py pycodestyle
    mv pycodestyle ~/bin
  fi
  # Early return on FB devserver
  if ! hascmd apt-get ; then return; fi
  install-dotnet
  nvim --headless +"LspInstall pyls_ms" +qall
  has-checkpoint python && return
  sudo apt-get install -y -q \
    python-dev \
    python3-pip \
    ipython3

  checkpoint python
}

install-language-rust() {
  if ! rustc --version > /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
  fi
  if ! hascmd rust-analyzer; then
    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux -o ~/bin/rust-analyzer
    chmod +x ~/bin/rust-analyzer
  fi
  rustup component add rust-src
  if [ ! -e ~/.bash.d/rust.sh ]; then
    echo 'source ~/.cargo/env' > ~/.bash.d/rust.sh
    echo 'export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"' >> ~/.bash.d/rust.sh
  fi
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
    local pkg="go1.15.6.linux-amd64.tar.gz"
    if [ ! -e "$pkg" ]; then
      wget -O "$pkg" "https://golang.org/dl/$pkg"
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
  if ! hascmd yarn; then
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update -qq
    sudo apt-get install -q -y --no-install-recommends yarn
  fi
  hascmd prettier || yarn global add prettier
  hascmd flow || yarn global add flow-bin
  cp-vim-bundle closetag
  cp-vim-bundle flow-coverage.nvim
}

install-language-cs() {
  if [ ! $WSL ]; then
    return
  fi
  install-dotnet
  nvim --headless +"LspInstall omnisharp" +qall
}


install-nvm() {
  # Early return on FB devserver
  if ! hascmd apt-get ; then return; fi
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
  local node_version=$(prompt "Install node version:" v12.17.0)
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
  # Enable multiverse
  sudo sed -i -e 's/# \(.* multiverse$\)/\1/' /etc/apt/sources.list
  sudo apt-get update -qq

  sudo apt-get install -q -y \
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
  [ ! $LINUX ] && return 1

  if [ ! -e /usr/share/applications/vim.desktop ]; then
    sudo cp vim.desktop /usr/share/applications
  fi
  if [ $SYMBOLIC ]; then
    link "$REPO/mimeapps.list" "$HOME/.local/share/applications/mimeapps.list"
  else
    cp mimeapps.list ~/.local/share/applications
  fi

  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.media-keys search "['<Super>space']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Shift><Alt>Return']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Alt>1']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Alt>2']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Alt>3']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Alt>4']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Alt>exclam']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Alt>at']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Alt>numbersign']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Alt>dollar']"
  gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>w']"
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>m']"
  gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
  gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 24
  gsettings set org.gnome.shell.extensions.dash-to-dock preferred-monitor 0
  gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
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
  rsync -lrp .config/autostart ~/.config/
}

setup-wsl() {
  if [ ! -e "$C_DRIVE/Windows/System32/win32yank.exe" ]; then
    pushd /tmp
    wget https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
    unzip win32yank-x64.zip
    mkdir -p "$C_DRIVE/tmp"
    mv win32yank.exe "$C_DRIVE/tmp"
    winsudo mv 'C:\tmp\win32yank.exe' 'C:\Windows\System32\'
    popd
  fi
  if [ ! -e "/etc/wsl.conf" ]; then
    echo -e "[automount]\noptions = case=off" | sudo tee /etc/wsl.conf
  fi
}

install-wsl-packages() {
  winsudo choco install -y chocolatey vlc skype googlechrome discord slack steam dropbox calibre dolphin mupen64plus geforce-experience sharpkeys
  if [ ! -e "$C_DRIVE/Program Files/Unity Hub" ]; then
    pushd /tmp
    [ ! -e UnityHubSetup.exe ] && wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe
    mkdir -p "$C_DRIVE/tmp"
    mv UnityHubSetup.exe "$C_DRIVE/tmp"
    winsudo 'C:\tmp\UnityHubSetup.exe'
    popd
  fi
}

setup-custom-packages() {
  if [ $WSL ]; then
    install-wsl-packages
    return
  fi
  setup-install-progs
  if ! hascmd docker && confirm "Install docker?" n; then
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
  sudo apt-get install -y -q gthumb
  if [[ -e ~/bin ]] && [[ ! -e ~/bin/youtube-dl ]]; then
    pushd ~/bin > /dev/null
    wget -O youtube-dl https://yt-dl.org/latest/youtube-dl
    chmod +x youtube-dl
    popd > /dev/null
  fi
}

main() {
  if [ "$(whoami)" == "root" ]; then
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
  if [ $WSL ]; then
    if [ -e "$C_DRIVE/tmp" ]; then
      rm -rf "$C_DRIVE/tmp"
    fi
    setup-wsl
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
  fi
  echo "Done"
}

main "$@"
