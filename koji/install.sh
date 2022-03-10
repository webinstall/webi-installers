#!/bin/bash
# shellcheck disable=SC2154

set -e
set -u

pkg_cmd_name="koji"

# IMPORTANT: this let's other functions know to expect this to be a single file
export WEBI_SINGLE=true

function pkg_get_current_version() {
    # 'koji version' has output in this format:
    #       koji 1.3.4
    # This trims it down to just the version number:
    #       1.3.4
    koji --version 2> /dev/null | cut -c6-
}

function pkg_install() {
    # $HOME/.local/opt/koji-1.3.4/bin
    mkdir -p "$pkg_src_bin"

    # mv ./koji* "$HOME/.local/opt/koji-1.3.4/bin/koji"
    mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

    # chmod a+x "$HOME/.local/opt/koji-1.3.4/bin/koji"
    chmod a+x "$pkg_src_cmd"
}

function pkg_link() {
    # rm -f "$HOME/.local/bin/koji"
    rm -f "$pkg_dst_cmd"

    # ln -s "$HOME/.local/opt/koji-1.3.4/bin/koji" "$HOME/.local/bin/koji"
    ln -s "$pkg_src_cmd" "$pkg_dst_cmd"
}
