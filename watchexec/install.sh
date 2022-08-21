#!/bin/sh
set -e
set -u

__init_watchexec() {

    #####################
    # Install watchexec #
    #####################

    # Every package should define these 6 variables
    pkg_cmd_name="watchexec"

    pkg_dst_cmd="$HOME/.local/bin/watchexec"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/watchexec-v$WEBI_VERSION/bin/watchexec"
    pkg_src_dir="$HOME/.local/opt/watchexec-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/watchexec-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./watchexec-*/watchexec ~/.local/opt/watchexec-v0.99.9/bin/watchexec
        mv ./watchexec-*/watchexec "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'watchexec --version' has output in this format:
        #       watchexec 0.99.9
        # This trims it down to just the version number:
        #       0.99.9
        watchexec --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_watchexec
