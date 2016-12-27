#!/bin/bash

command -v notify > /dev/null 2>&1 || notify() {
  if [ -z "$IFTTT_TOKEN" ]; then
    echo "Must have env var IFTTT_TOKEN to use notify"
    return 1
  fi
  curl -X POST -d "value1=$(hostname)&value2=$1" "https://maker.ifttt.com/trigger/notify/with/key/$IFTTT_TOKEN"
}
