#!/bin/sh
set -e
set -u

__init_vps_utils() {

    rm -f "$HOME/.local/bin/myip" "$HOME/.local/bin/vps-myip" "$HOME/.local/bin/vps-addswap" "$HOME/.local/bin/cap-net-bind"
    webi_download "$WEBI_HOST/packages/vps-utils/cap-net-bind.sh" "$HOME/.local/bin/cap-net-bind"
    webi_download "$WEBI_HOST/packages/vps-utils/vps-addswap.sh" "$HOME/.local/bin/vps-addswap"
    webi_download "$WEBI_HOST/packages/myip/myip.sh" "$HOME/.local/bin/myip"
    ln -s "$HOME/.local/bin/myip" "$HOME/.local/bin/vps-myip"
    chmod a+x "$HOME/.local/bin/cap-net-bind"
    chmod a+x "$HOME/.local/bin/myip"
    chmod a+x "$HOME/.local/bin/vps-"*
}

__init_vps_utils
