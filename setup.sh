#!/bin/bash -ex

main() {
    local test_arg=
    if [ "$1" == "test" ]; then
        test_arg="test=True"
    fi

    git submodule update --init --recursive > /dev/null
    tar -zxf thin.tgz
    local here=$(readlink -f .)
    sed -i -e "s|<<file_root>>|$here/salt|" -e "s|<<home>>|$HOME|" -e "s|<<user>>|$USER|" config/minion
    # Don't apt-get update if we're just testing. It takes too long
    if [ ! "$test_arg" ]; then
        sudo apt-get update -qq
        sudo apt-get upgrade -y -qq
    fi
    if [ ! `which pip` ]; then
        sudo easy_install pip
    fi
    sudo pip install msgpack-python jinja2 pyyaml
    sudo python salt-call --local -l warning -c "$here/config" state.highstate $test_arg
    sed -i -e "s|$here/salt|<<file_root>>|" -e "s|$HOME|<<home>>|" -e "s|$USER|<<user>>|" config/minion
    git clean -fxd > /dev/null
}

main "$@"
