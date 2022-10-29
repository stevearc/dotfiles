#!/bin/bash
set -e
unlink "$HOME/.config/$1"
cp -r "$HOME/dotfiles/.config/$1" "$HOME/.config/$1"
