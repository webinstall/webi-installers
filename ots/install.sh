#!/bin/sh

# shellcheck disable=SC2034
# "'pkg_cmd_name' appears unused. Verify it or export it."

__init_ots() {
    set -e
    set -u

    ##################
    # Install ots #
    ##################

    pkg_cmd_name="ots"

    pkg_dst_cmd="$HOME/.local/bin/ots"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/ots-v$WEBI_VERSION/bin/ots"
    pkg_src_dir="$HOME/.local/opt/ots-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname "${pkg_src_cmd}")"
        mv ots "${pkg_src_cmd}"
    }

    pkg_get_current_version() {
        ots --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_ots
