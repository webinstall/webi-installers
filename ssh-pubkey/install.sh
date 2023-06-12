#!/bin/sh
set -e
set -u

__install_ssh_pubkey() {
    rm -f "$HOME/.local/bin/ssh-pubkey"
    webi_download \
        "$WEBI_HOST/packages/ssh-pubkey/ssh-pubkey" \
        "$HOME/.local/bin/ssh-pubkey"
    chmod a+x "$HOME/.local/bin/ssh-pubkey"

    # run the command
    "$HOME/.local/bin/ssh-pubkey"
}

__install_ssh_pubkey
