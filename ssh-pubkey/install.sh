#!/bin/bash
set -e
set -u

function __install_ssh_pubkey() {
    MY_CMD="ssh-pubkey"

    rm -f "$HOME/.local/bin/$MY_CMD"
    webi_download "$WEBI_HOST/packages/$MY_CMD/$MY_CMD.sh" "$HOME/.local/bin/$MY_CMD"
    chmod a+x "$HOME/.local/bin/$MY_CMD"

    # run the command
    "$HOME/.local/bin/$MY_CMD"
}

__install_ssh_pubkey
