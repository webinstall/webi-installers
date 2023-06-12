#!/bin/sh
set -e
set -u

__install_ssh_setpass() {
    rm -f "$HOME/.local/bin/ssh-setpass"
    webi_download \
        "$WEBI_HOST/packages/ssh-setpass/ssh-setpass" \
        "$HOME/.local/bin/ssh-setpass"
    chmod a+x "$HOME/.local/bin/ssh-setpass"
}

__install_ssh_setpass
