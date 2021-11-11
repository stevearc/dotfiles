#!/bin/bash
set -e

# Make sure we're using the closest mirrors
sudo pacman-mirrors --geoip

sudo pamac install --no-confirm git
git clone https://github.com/stevearc/dotfiles
