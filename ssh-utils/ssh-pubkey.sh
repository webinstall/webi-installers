#!/bin/bash

{
    set -e
    set -u

    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p "$HOME/.ssh/"
        chmod 0700 "$HOME/.ssh/"
    fi

    if [ ! -f "$HOME/.ssh/config" ]; then
        # for the benefit of VSCode
        touch "$HOME/.ssh/config"
        chmod 0644 "$HOME/.ssh/config"
    fi

    if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
        touch "$HOME/.ssh/authorized_keys"
        chmod 0600 "$HOME/.ssh/authorized_keys"
    fi

    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/id_rsa" -q -N ""
        >&2 echo ""
    fi

    if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        ssh-keygen -y -f "$HOME/.ssh/id_rsa" > "$HOME/.ssh/id_rsa.pub"
        >&2 echo ""
    fi

    # TODO use the comment (if any) for the name of the file
    >&2 echo ""
    >&2 echo "~/Downloads/id_rsa.$(whoami).pub":
    >&2 echo ""
    rm -f "$HOME/Downloads/id_rsa.$(whoami).pub"
    cp -r "$HOME/.ssh/id_rsa.pub" "$HOME/Downloads/id_rsa.$(whoami).pub"
    cat "$HOME/Downloads/id_rsa.$(whoami).pub"
    >&2 echo ""
}
