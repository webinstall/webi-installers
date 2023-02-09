#!/bin/sh
set -e
set -u

__init_aliasman() {

    ######################
    # Install aliasman #
    ######################

    # Every package should define these 6 variables
    pkg_cmd_name="aliasman"

    pkg_dst_cmd="$HOME/.local/bin/aliasman"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/aliasman-v$WEBI_VERSION/bin/aliasman"
    pkg_src_dir="$HOME/.local/opt/aliasman-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/aliasman-v1.0.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./*aliasman*/aliasman ~/.local/opt/aliasman-v1.0.0/bin/aliasman
        mv ./*aliasman*/aliasman "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'aliasman version' has output in this format:
        #       aliasman v1.0.0 (2023-01-15)
        #       Copyright 2023 AJ ONeal
        # This trims it down to just the version number:
        #       1.0.0
        aliasman version | head -n 1 | cut -d ' ' -f 2 | sed 's:^v::'
    }
}

__init_aliasman
