#!/bin/bash
setxkbmap -option ctrl:nocaps
nm-applet
sleep .01
nitrogen --restore
