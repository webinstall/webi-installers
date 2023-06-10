#!/bin/sh
set -e
set -u

__install_ssh_authorize() {
    my_cmd="ssh-authorize"

    rm -f "$HOME/.local/bin/${my_cmd}"

    webi_download \
        "$WEBI_HOST/packages/${my_cmd}/${my_cmd}" \
        "$HOME/.local/bin/${my_cmd}"

    chmod a+x "$HOME/.local/bin/${my_cmd}"
}

__install_ssh_authorize
