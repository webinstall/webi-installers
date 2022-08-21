#!/bin/sh
set -e
set -u

__init_shfmt() {

    ##################
    # Install shfmt #
    ##################

    pkg_cmd_name="shfmt"

    pkg_dst_cmd="$HOME/.local/bin/shfmt"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/shfmt-v$WEBI_VERSION/bin/shfmt"
    pkg_src_dir="$HOME/.local/opt/shfmt-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # ~/.local/opt/shfmt-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        shfmt --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_shfmt
