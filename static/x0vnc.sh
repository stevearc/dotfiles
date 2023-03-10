#! /bin/bash

# Export an environment variable of the Display Manager
export XAUTHORITY="/var/run/lightdm/root/:0"

# Start VNC server for :0 display in background
## Set path to binary file
VNC_BIN=/usr/bin/x0vncserver

## Set parameters
## WARNING: This use of SecurityTypes is insecure.
##          Anyone can connect to the VNC server without any authentication.
PARAMS="-display :0 -SecurityTypes None"

## Launch VNC server
($VNC_BIN $PARAMS)

# Provide dirty exit code so that systemd
# will restart the server when a user logs out
exit 1
