#!/bin/sh

__init_syncthing() {
    set -e
    set -u

    #####################
    # Install syncthing #
    #####################

    # Every package should define these 6 variables
    pkg_cmd_name="syncthing"

    pkg_dst_cmd="$HOME/.local/bin/syncthing"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/syncthing-v$WEBI_VERSION/bin/syncthing"
    pkg_src_dir="$HOME/.local/opt/syncthing-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/syncthing-v1.12.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./syncthing* "$HOME/.local/opt/syncthing-v1.12.1/bin/syncthing"
        mv ./syncthing*/"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/syncthing-v1.12.1/bin/syncthing"
        chmod a+x "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'syncthing version' has output in this format:
        #       syncthing v1.12.1 "Fermium Flea" (go1.15.5 darwin-amd64) teamcity@build.syncthing.net 2020-12-06 12:46:27 UTC
        # This trims it down to just the version number:
        #       1.12.1
        syncthing --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }
}

__init_syncthing
