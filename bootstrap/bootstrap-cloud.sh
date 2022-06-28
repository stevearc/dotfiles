#!/usr/bin/env bash
# Bootstraps a basic Ubuntu cloud machine
set -e

apt update
adduser stevearc || :
adduser stevearc admin
cp -r ~/.ssh /home/stevearc
chown -R stevearc:stevearc /home/stevearc/.ssh
apt install -y -q bsdmainutils git
cd /home/stevearc
su stevearc -c "git clone --recursive https://github.com/stevearc/dotfiles"
cat << EOF >>.bashrc
echo "Running setup"
cd ~/dotfiles
rm ~/.bashrc
./run dotfiles
source ~/.bashrc
./run install common
./run install neovim
./run language common
EOF
