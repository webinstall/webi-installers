#!/bin/bash

{
    set -e
    set -u

    rm -f "$HOME/.local/bin/setcap-netbind"
    webi_download "$WEBI_HOST/packages/setcap-netbind/setcap-netbind.sh" "$HOME/.local/bin/setcap-netbind"
    chmod a+x "$HOME/.local/bin/setcap-netbind"
}
