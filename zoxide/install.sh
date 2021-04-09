#!/bin/bash

function __init_zoxide() {
    set -e
    set -u

    ##################
    # Install zoxide #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="zoxide"

    pkg_dst_cmd="$HOME/.local/bin/zoxide"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/zoxide-v$WEBI_VERSION/bin/zoxide"
    pkg_src_dir="$HOME/.local/opt/zoxide-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # mkdir -p "~/.local/opt/zoxide-v0.99.9/bin"
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./zoxide-*/zoxide "~/.local/opt/zoxide-v0.99.9/bin/zoxide"
        mv ./zoxide-*/zoxide "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'zoxide --version' has output in this format:
        #       zoxide v0.5.0-31-g8452961
        # This trims it down to just the version number:
        #       0.5.0
        zoxide --version 2>/dev/null | head -n 1 | cut -d '-' -f 1 | cut -b '9-'
    }

}

__init_zoxide
