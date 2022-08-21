#!/bin/sh
set -e
set -u

__init_lsd() {

    ###############
    # Install lsd #
    ###############

    # Every package should define these 6 variables
    pkg_cmd_name="lsd"

    pkg_dst_cmd="$HOME/.local/bin/lsd"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lsd-v$WEBI_VERSION/bin/lsd"
    pkg_src_dir="$HOME/.local/opt/lsd-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/lsd-v0.17.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./lsd-*/lsd ~/.local/opt/lsd-v0.17.0/bin/lsd
        mv ./lsd-*/lsd "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'lsd --version' has output in this format:
        #       lsd 0.17.0
        # This trims it down to just the version number:
        #       0.17.0
        lsd --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_lsd
