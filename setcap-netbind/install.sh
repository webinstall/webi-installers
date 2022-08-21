#!/bin/sh
set -e
set -u

__install_setcap_netbind() {
    # remove prior version, if exists
    rm -f ~/.local/bin/setcap-netbind

    # download latest version, directly to ~/.local/bin
    webi_download \
        "$WEBI_HOST/packages/setcap-netbind/setcap-netbind.sh" \
        ~/.local/bin/setcap-netbind

    # make executable
    chmod a+x ~/.local/bin/setcap-netbind
}

__install_setcap_netbind
