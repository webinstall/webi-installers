#!/bin/bash

{
    set -e
    set -u

    my_bin="$1"
    if [ -z "$(which $my_bin)"]; then
        echo "'$my_bin' not found"
        exit 1
    fi
    my_sudo=""
    if [ -n "$(command -v sudo)" ]; then
        my_sudo=sudo
    fi
    $my_sudo setcap 'cap_net_bind_service=+ep' $(readlink -f $(which $my_bin))
}
