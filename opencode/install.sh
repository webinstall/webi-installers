#!/bin/sh
# shellcheck disable=SC2034

set -e
set -u

__init_opencode() {

    ####################
    # Install opencode #
    ####################

    pkg_cmd_name="opencode"

    pkg_dst_cmd="$HOME/.local/bin/opencode"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/opencode-v$WEBI_VERSION/bin/opencode"
    pkg_src_dir="$HOME/.local/opt/opencode-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # ~/.local/opt/opencode-v1.2.27/bin/
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./opencode ~/.local/opt/opencode-v1.2.27/bin/opencode
        mv ./opencode "$pkg_src_cmd"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'opencode --version' outputs just the version number:
        #       1.2.27
        opencode --version 2> /dev/null |
            head -n 1
    }

}

__init_opencode
