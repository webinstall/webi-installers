#!/bin/bash

function __init_lf() {
    set -e
    set -u

    ##################
    # Install lf #
    ##################
    
    pkg_cmd_name="lf"

    pkg_dst_cmd="$HOME/.local/bin/lf"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lf-v$WEBI_VERSION/bin/lf"
    pkg_src_dir="$HOME/.local/opt/lf-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname $pkg_src_cmd)"
        mv ./lf-*/lf "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        echo $(lf --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
    }

}

__init_lf
