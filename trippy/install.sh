#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_trippy() {
    set -e
    set -u

    ##################
    # Install trippy #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="trippy"

    pkg_dst_cmd="$HOME/.local/bin/trippy"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/trippy-v$WEBI_VERSION/bin/trippy"
    pkg_src_dir="$HOME/.local/opt/trippy-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/trippy-v0.99.9/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./trippy-*/trippy ~/.local/opt/trippy-v0.99.9/bin/trippy
        mv ./trippy-*/* "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'trippy --version' has output in this format:
        #       trippy 0.99.9 (rev abcdef0123)
        # This trims it down to just the version number:
        #       0.99.9
        trippy --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_trippy
