#!/bin/bash

function __init_mutagen() {
    set -e
    set -u

    ##################
    # Install mutagen #
    ##################

    pkg_cmd_name="mutagen"

    pkg_dst_cmd="$HOME/.local/bin/mutagen"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/mutagen-v$WEBI_VERSION/bin/mutagen"
    pkg_src_dir="$HOME/.local/opt/mutagen-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        mkdir -p "$(dirname $pkg_src_cmd)"

        mv ./mutagen "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        echo $(mutagen --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
    }

}

__init_mutagen
