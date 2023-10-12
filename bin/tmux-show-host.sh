#!/bin/bash
set -e
if [ -e /pay/conf/mydev-remote-name ]; then
  cat /pay/conf/mydev-remote-name
else
  hostname | cut -f 1 -d .
fi
