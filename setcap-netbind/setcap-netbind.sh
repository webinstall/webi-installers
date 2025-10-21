#!/bin/sh
set -e
set -u

main() {
    a_exename="${1}"
    # ex: node
    if ! command -v "${a_exename}" > /dev/null; then
        echo "setcap-netbind: '${a_exename}' not found"
        exit 1
    fi

    cmd_sudo=""
    if command -v sudo > /dev/null; then
        cmd_sudo=sudo
    fi

    # get full path
    # ex: ~/.local/opt/node/bin/node
    a_exename="$(command -v "${a_exename}")"

    # get canonical full path
    # ex: ~/.local/opt/node-v16.13.0/bin/node
    a_exename="$(readlink -f "${a_exename}")"

    # ex: sudo setcap 'cap_net_bind_service=+ep' ~/.local/opt/node-v16.13.0/bin/node"
    $cmd_sudo setcap 'cap_net_bind_service=+ep' "${a_exename}"
}

main "${1-}"
