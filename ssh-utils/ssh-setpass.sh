#!/bin/bash

function __init_ssh_setpass() {
    set -e
    set -u

    ssh-keygen -p -f "$HOME/.ssh/id_rsa"
}

__init_ssh_setpass
