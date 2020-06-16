#!/bin/bash

# This file only defines custom functions which may be unique to installing Caddy.
# For the generic functions (version comparison, downloading, symlinking) which
# are used by almost all installers, see `template.bash`:
#   - https://github.com/webinstall/packages/branches/master/webi/template.bash

set -e
set -u

pkg_cmd_name="caddy"
WEBI_SINGLE=true

pkg_get_current_version() {
    # 'caddy version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.0.0
    echo "$(caddy version 2>/dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::')"
}

pkg_install() {
    # $HOME/.local/xbin
    mkdir -p "$pkg_src_bin"

    # mv ./caddy* "$HOME/.local/xbin/caddy-v2.0.0"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/xbin/caddy-v2.0.0"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/caddy"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/xbin/caddy-v2.0.0" "$HOME/.local/bin/caddy"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
