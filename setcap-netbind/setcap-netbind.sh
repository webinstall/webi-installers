#!/bin/sh
set -e
set -u

main() {
    my_bin="${1}"
    # ex: node
    if [ -z "$(command -v "${my_bin}")" ]; then
        echo "setcap-netbind: '${my_bin}' not found"
        exit 1
    fi

    my_sudo=""
    if [ -n "$(command -v sudo)" ]; then
        my_sudo=sudo
    fi

    # get full path
    # ex: ~/.local/opt/node/bin/node
    my_bin="$(command -v "${my_bin}")"

    # get canonical full path
    # ex: ~/.local/opt/node-v16.13.0/bin/node
    my_bin="$(readlink -f "${my_bin}")"

    # ex: sudo setcap 'cap_net_bind_service=+ep' ~/.local/opt/node-v16.13.0/bin/node"
    "${my_sudo}" setcap 'cap_net_bind_service=+ep' "${my_bin}"
}

main "${1-}"
