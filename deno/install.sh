#!/bin/sh

# The custom functions for Deno are here.
# For the generic functions - version checks, download, extract, etc:
# See https://github.com/webinstall/packages/branches/master/_webi/template.sh

set -e
set -u

pkg_cmd_name="deno"

# IMPORTANT: this let's other functions know to expect this to be a single file
WEBI_SINGLE=true

pkg_get_current_version() {
    # 'deno --version' has output in this format:
    #       deno 1.1.0
    #       v8 8.4.300
    #       typescript 3.9.2
    # This trims it down to just the version number:
    #       1.1.1
    deno --version 2> /dev/null | head -n 1 | cut -d' ' -f2
}

pkg_install() {
    # $HOME/.local/xbin
    mkdir -p "$pkg_src_bin"

    # mv ./deno* "$HOME/.local/xbin/deno-v1.1.0"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/xbin/deno-v1.1.0"
    chmod a+x "$pkg_src_cmd"
}

pkg_link() {
    # rm -f "$HOME/.local/bin/deno"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/xbin/deno-v1.1.0" "$HOME/.local/bin/deno"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
