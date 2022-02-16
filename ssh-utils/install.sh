#!/bin/bash

function __install_ssh_utils() {
    rm -f \
        "$HOME/.local/bin/ssh-pubkey" \
        "$HOME/.local/bin/ssh-setpass" \
        "$HOME/.local/bin/ssh-adduser"
    # done

    webi_download \
        "$WEBI_HOST/packages/ssh-pubkey/ssh-pubkey.sh" \
        "$HOME/.local/bin/ssh-pubkey"
    webi_download \
        "$WEBI_HOST/packages/ssh-setpass/ssh-setpass.sh" \
        "$HOME/.local/bin/ssh-setpass"
    webi_download \
        "$WEBI_HOST/packages/ssh-adduser/ssh-adduser.sh" \
        "$HOME/.local/bin/ssh-adduser"

    chmod a+x "$HOME/.local/bin/ssh-"*
}

__install_ssh_utils
