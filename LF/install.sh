#!/bin/bash

function __init_lf() {
    set -e
    set -u

    ##################
    # Install lf #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="lf"

    pkg_dst_cmd="$HOME/.local/bin/lf"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lf-v$WEBI_VERSION/bin/lf"
    pkg_src_dir="$HOME/.local/opt/lf-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/lf-v0.99.9/bin
        mkdir -p "$(dirname $pkg_src_cmd)"

        # mv ./lf-*/lf ~/.local/opt/lf-v0.99.9/bin/lf
        mv ./lf-*/lf "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'lf --version' has output in this format:
        #       lf 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        echo $(lf --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
    }

}

__init_lf
