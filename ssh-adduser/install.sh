#!/bin/bash
set -e
set -u

__install_ssh_adduser() {
    my_cmd="ssh-adduser"

    rm -f "$HOME/.local/bin/${my_cmd}"

    webi_download \
        "$WEBI_HOST/packages/${my_cmd}/${my_cmd}.sh" \
        "$HOME/.local/bin/${my_cmd}"

    chmod a+x "$HOME/.local/bin/${my_cmd}"

    # run the command
    "$HOME/.local/bin/${my_cmd}"
}

__install_ssh_adduser
