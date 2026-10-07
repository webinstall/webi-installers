#!/bin/sh
# shellcheck disable=SC2034

__init_ndx() {
    set -e
    set -u

    ###############
    # Install ndx #
    ###############

    # Every package should define these 6 variables
    pkg_cmd_name="ndx"

    pkg_dst_cmd="$HOME/.local/bin/ndx"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/ndx-v$WEBI_VERSION/bin/ndx"
    pkg_src_dir="$HOME/.local/opt/ndx-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    WEBI_SINGLE=true

    pkg_install() {
        # ~/.local/opt/ndx-v1.0.1/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./ndx ~/.local/opt/ndx-v1.0.1/bin/ndx
        mv ./ndx "$pkg_src_cmd"

        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'ndx --version' has output in this format:
        #       ndx 1.0.1 (4c820c6)
        # This trims it down to just the version number:
        #       1.0.1
        ndx --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }
}

__init_ndx
