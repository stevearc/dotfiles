#!/bin/bash
setxkbmap -option ctrl:nocaps
nm-applet
sleep .1
nitrogen --restore
