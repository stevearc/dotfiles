#!/usr/bin/env bash
# Bootstraps a basic Arch Linux cloud machine
set -ex

pacman -Syu --noconfirm
id -u stevearc 2>/dev/null || useradd -m -G wheel -s /bin/bash stevearc
echo "stevearc ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/10-stevearc-no-pass
cp -r ~/.ssh /home/stevearc
chown -R stevearc:stevearc /home/stevearc/.ssh
pacman -S --noconfirm --needed git base-devel
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
echo "Done!"
