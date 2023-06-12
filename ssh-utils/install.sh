#!/bin/sh
set -e
set -u

__install_ssh_utils() {
    rm -f "$HOME/.local/bin/ssh-authorize"
    webi_download \
        "$WEBI_HOST/packages/ssh-authorize/ssh-authorize" \
        "$HOME/.local/bin/ssh-authorize"
    chmod a+x "$HOME/.local/bin/ssh-authorize"

    rm -rf "$HOME/.local/bin/ssh-adduser"
    webi_download \
        "$WEBI_HOST/packages/ssh-adduser/ssh-adduser" \
        "$HOME/.local/bin/ssh-adduser"
    chmod a+x "$HOME/.local/bin/ssh-adduser"

    rm -rf "$HOME/.local/bin/ssh-pubkey"
    webi_download \
        "$WEBI_HOST/packages/ssh-pubkey/ssh-pubkey" \
        "$HOME/.local/bin/ssh-pubkey"
    chmod a+x "$HOME/.local/bin/ssh-pubkey"

    rm -rf "$HOME/.local/bin/ssh-setpass"
    webi_download \
        "$WEBI_HOST/packages/ssh-setpass/ssh-setpass" \
        "$HOME/.local/bin/ssh-setpass"
    chmod a+x "$HOME/.local/bin/ssh-setpass"

    rm -rf "$HOME/.local/bin/sshd-prohibit-password"
    webi_download \
        "$WEBI_HOST/packages/sshd-prohibit-password/sshd-prohibit-password" \
        "$HOME/.local/bin/sshd-prohibit-password"
    chmod a+x "$HOME/.local/bin/sshd-prohibit-password"
}

__install_ssh_utils
