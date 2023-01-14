#!/usr/bin/env bash
# Bootstraps a basic Ubuntu cloud machine
set -ex

apt update
id -u stevearc 2>/dev/null || adduser --system --group --disabled-password --gecos "" --shell /bin/bash stevearc
groups stevearc | grep admin || adduser stevearc admin
echo "stevearc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-stevearc-no-pass
cp -r ~/.ssh /home/stevearc
chown -R stevearc:stevearc /home/stevearc/.ssh
apt install -y -q bsdmainutils git
cd /home/stevearc
su stevearc -c "git clone --recursive -j 8 https://github.com/stevearc/dotfiles"
echo "Running setup"
rm -f /home/stevearc/.bashrc
if [ ! -e .bash_profile ]; then
  su stevearc -c "echo '[ -e ~/.bashrc ] && source ~/.bashrc' > .bash_profile"
  chown stevearc:stevearc .bash_profile
fi
su stevearc -l -c "cd ~/dotfiles && ./run dotfiles"
su stevearc -l -c "cd ~/dotfiles && ./run install common"
su stevearc -l -c "cd ~/dotfiles && ./scripts/install_neovim.sh stable"
su stevearc -l -c "cd ~/dotfiles && ./run install neovim"
su stevearc -l -c "cd ~/dotfiles && ./run language common"
