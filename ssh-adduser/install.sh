#!/bin/sh
set -e
set -u

__install_ssh_adduser() {
    # ssh-adduser
    rm -f "$HOME/.local/bin/ssh-adduser"
    webi_download \
        "$WEBI_HOST/packages/ssh-adduser/ssh-adduser" \
        "$HOME/.local/bin/ssh-adduser"
    chmod a+x "$HOME/.local/bin/ssh-adduser"

    # sshd-prohibit-password
    rm -f "$HOME/.local/bin/sshd-prohibit-password"
    webi_download \
        "$WEBI_HOST/packages/sshd-prohibit-password/sshd-prohibit-password" \
        "$HOME/.local/bin/sshd-prohibit-password"
    chmod a+x "$HOME/.local/bin/sshd-prohibit-password"

    # run the commands
    export SSH_ADDUSER_AUTO=true
    "$HOME/.local/bin/ssh-adduser"

    # TODO create vps-init or the like to do both
    "$HOME/.local/bin/sshd-prohibit-password"
}

__install_ssh_adduser
