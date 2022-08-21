#!/bin/sh

# "This is too simple" you say! "Where is the magic!?" you ask.
# There is no magic!
# The custom functions for Caddy are here.
# The generic functions - version checks, download, extract, etc - are here:
#   - https://github.com/webinstall/packages/branches/master/_webi/template.sh

set -e
set -u

pkg_cmd_name="caddy"

# IMPORTANT: this let's other functions know to expect this to be a single file
WEBI_SINGLE=true

pkg_get_current_version() {
    # 'caddy version' has output in this format:
    #       v2.1.0 h1:pQSaIJGFluFvu8KDGDODV8u4/QRED/OPyIR+MWYYse8=
    # This trims it down to just the version number:
    #       2.1.0
    caddy version 2> /dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::'
}

pkg_install() {
    # $HOME/.local/opt/caddy-v2.1.0/bin
    mkdir -p "$pkg_src_bin"

    # mv ./caddy* "$HOME/.local/opt/caddy-v2.1.0/bin/caddy"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/opt/caddy-v2.1.0/bin/caddy"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/caddy"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/opt/caddy-v2.1.0/bin/caddy" "$HOME/.local/bin/caddy"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
