#!/bin/bash

main() {
  for plugdir in vimplugins/*; do
    echo "    $plugdir"
    cd $plugdir
    local branchname=$(git remote show origin | grep HEAD | cut -f 2 -d: | tr -d '[:space:]')
    git checkout -q "$branchname"
    git pull --rebase
    cd -
  done
}

main "$@"
