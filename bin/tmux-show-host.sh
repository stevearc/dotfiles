#!/bin/bash
set -e
if [ -e /pay/conf/box-name ]; then
  cat /pay/conf/box-name
else
  hostname | cut -f 1 -d .
fi
