#!/bin/bash

{
    set -e
    set -u

    rm -f "$HOME/.local/bin/myip"
    webi_download  "$WEBI_HOST/packages/myip/myip.sh" "$HOME/.local/bin/myip"
    chmod a+x "$HOME/.local/bin/myip"

    "$HOME/.local/bin/myip"
}
