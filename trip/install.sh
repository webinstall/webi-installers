#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_trip() {
    set -e
    set -u

    ################
    # Install trip #
    ################

    # Every package should define these 6 variables
    pkg_cmd_name="trip"

    pkg_dst_cmd="$HOME/.local/bin/trip"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/trippy-v$WEBI_VERSION/bin/trip"
    pkg_src_dir="$HOME/.local/opt/trippy-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/trippy-v0.8.0/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./trippy-*/trip ~/.local/opt/trippy-v0.8.0/bin/trip
        mv ./trippy-*/trip "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'trip -V' has output in this format:
        #       trip 0.8.0
        # This trims it down to just the version number:
        #       0.8.0
        trip -V 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_trip
