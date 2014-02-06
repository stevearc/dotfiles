#!/bin/bash -ex

main() {
    git submodule update --init --recursive > /dev/null
    if [ ! `which sshpass` ]; then
        sudo apt-get install -y sshpass
    fi
    if [ ! `which pip` ]; then
        sudo easy_install pip
    fi
    if [ ! `which virtualenv` ]; then
        sudo pip install virtualenv
    fi
    if [ ! -e 'venv' ]; then
        virtualenv venv
    fi
    . venv/bin/activate
    pip install ansible dopy

    ansible-playbook -i inventory -v "$@"
}

main "$@"
