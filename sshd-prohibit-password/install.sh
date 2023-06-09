#!/bin/sh
set -e
set -u

__install_sshd_prohibit_password() {
    my_cmd="sshd-prohibit-password"

    rm -f "$HOME/.local/bin/${my_cmd}"

    webi_download \
        "$WEBI_HOST/packages/${my_cmd}/${my_cmd}" \
        "$HOME/.local/bin/${my_cmd}"

    chmod a+x "$HOME/.local/bin/${my_cmd}"

    # run the command
    "$HOME/.local/bin/${my_cmd}"
}

__install_sshd_prohibit_password
