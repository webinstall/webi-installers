#!/bin/sh

__init_bls() {
    set -e
    set -u

    ####################
    # Install bls #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="bls"

    pkg_dst_cmd="$HOME/.local/bin/bls"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/bls-v$WEBI_VERSION/bin/bls"
    pkg_src_dir="$HOME/.local/opt/bls-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/bls-v0.6.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./bls* "$HOME/.local/opt/bls-v0.6.5/bin/bls"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/bls-v0.6.5/bin/bls"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        bls --version
    }

}

__init_bls
