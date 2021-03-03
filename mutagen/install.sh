#!/bin/bash

function __init_mutagen() {
    set -e
    set -u

    ###################
    # Install mutagen #
    ###################

    pkg_cmd_name="mutagen"

    pkg_dst_cmd="$HOME/.local/bin/mutagen"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/mutagen-v$WEBI_VERSION/bin/mutagen"
    pkg_src_dir="$HOME/.local/opt/mutagen-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/mutagen-v0.11.8/bin
        mkdir -p "$(dirname $pkg_src_cmd)"

        # mv ./mutagen* "$HOME/.local/opt/mutagen-v0.11.8/bin/mutagen"
        mv ./mutagen "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/mutagen-v0.11.8/bin/mutagen"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'mutagen version' has output in this format:
        #       0.11.8
        # This trims it down to just the version number:
        #       0.11.8
        echo $(mutagen version 2>/dev/null | head -n 1 | cut -d ' ' -f1)
    }

}

__init_mutagen
