#!/bin/bash

set -e
set -u

pkg_cmd_name="node"

pkg_get_current_version() {
    # 'node --version' has output in this format:
    #       v12.8.0
    # This trims it down to just the version number:
    #       12.8.0
    echo "$(node --version 2>/dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^v::')"
}

pkg_install() {
    # mkdir -p $HOME/.local/opt
    mkdir -p "$(dirname $pkg_src)"

    # mv ./node* "$HOME/.local/opt/node-v14.4.0"
    mv ./"$pkg_cmd_name"* "$pkg_src"
}

pkg_link() {
    # rm -f "$HOME/.local/opt/node"
    rm -f "$pkg_dst"

    # ln -s "$HOME/.local/opt/node-v14.4.0" "$HOME/.local/opt/node"
    ln -s "$pkg_src" "$pkg_dst"
}

pkg_done_message() {
    echo "Installed 'node' and 'npm' at $pkg_dst"
}
