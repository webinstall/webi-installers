#!/bin/bash
set -e
set -u

function main() {
    my_key="${1:-"${HOME}/.ssh/id_rsa"}"
    ssh-keygen -p -f "${my_key}"
}

main "${1:-}"
