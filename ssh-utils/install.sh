#!/bin/bash

function __init_ssh_utils() {
    rm -f "$HOME/.local/bin/ssh-pubkey" "$HOME/.local/bin/ssh-setpass" "$HOME/.local/bin/ssh-adduser"
    webi_download "$WEBI_HOST/packages/ssh-utils/ssh-pubkey.sh" "$HOME/.local/bin/ssh-pubkey"
    webi_download "$WEBI_HOST/packages/ssh-utils/ssh-setpass.sh" "$HOME/.local/bin/ssh-setpass"
    webi_download "$WEBI_HOST/packages/ssh-utils/ssh-adduser.sh" "$HOME/.local/bin/ssh-adduser"
    chmod a+x "$HOME/.local/bin/ssh-"*
}

__init_ssh_utils
