#!/bin/bash
DEFAULT_PORT=8585
CMDR_PATH="$(dirname $0)"

main() {
  PATH="$CMDR_PATH:$PATH"
  local port="${1-$DEFAULT_PORT}"
  while true; do
    local input="$(nc -l $port)"
    local cmd="${input%% *}"
    local args="${input:${#cmd}}"
    local cmd="_cmdr_${cmd}"
    if command -v "$cmd" > /dev/null 2>&1; then
        echo "$cmd $args"
        $cmd $args
      else
        echo "Unrecognized command: '$cmd'"
    fi
  done
}

main "$@"
