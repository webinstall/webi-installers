#!/bin/bash
set -e
set -u

__install_ssh_setpass() {
    my_cmd="ssh-setpass"

    rm -f "$HOME/.local/bin/${my_cmd}"

    webi_download \
        "$WEBI_HOST/packages/${my_cmd}/${my_cmd}.sh" \
        "$HOME/.local/bin/${my_cmd}"

    chmod a+x "$HOME/.local/bin/${my_cmd}"

    # run the command
    echo ''
    echo 'Set passphrase for ~/.ssh/id_rsa?'
    "$HOME/.local/bin/${my_cmd}"
}

__install_ssh_setpass
