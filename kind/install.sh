#!/bin/sh

__init_kind() {
    set -e
    set -u

    ##################
    # Install kind #
    ##################

    pkg_cmd_name="kind"

    pkg_dst_cmd="$HOME/.local/bin/kind"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/kind-v$WEBI_VERSION/bin/kind"
    pkg_src_dir="$HOME/.local/opt/kind-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    WEBI_SINGLE=true

    pkg_get_current_version() {
        kind --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_kind
