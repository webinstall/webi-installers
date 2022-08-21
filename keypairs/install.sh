#!/bin/sh

__init_keypairs() {
    set -e
    set -u

    ####################
    # Install keypairs #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="keypairs"

    pkg_dst_cmd="$HOME/.local/bin/keypairs"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/keypairs-v$WEBI_VERSION/bin/keypairs"
    pkg_src_dir="$HOME/.local/opt/keypairs-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/keypairs-v0.6.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./keypairs* "$HOME/.local/opt/keypairs-v0.6.5/bin/keypairs"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/keypairs-v0.6.5/bin/keypairs"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'keypairs version' has output in this format:
        #       keypairs v0.6.5 (7e6fd17) 2020-10-21T06:26:46Z
        # This trims it down to just the version number:
        #       0.6.5
        keypairs --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_keypairs
