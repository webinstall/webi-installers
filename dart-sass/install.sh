#!/bin/bash

function __init_dart-sass() {
    set -e
    set -u

    ##################
    # Install dart-sass #
    ##################

    pkg_cmd_name="dart-sass"

    pkg_dst_cmd="$HOME/.local/bin/dart-sass"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/dart-sass-v$WEBI_VERSION/bin/dart-sass"
    pkg_src_dir="$HOME/.local/opt/dart-sass-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        mkdir -p "$(dirname $pkg_src_cmd)"
        mv ./dart-sass-*/dart-sass "$pkg_src_cmd"
        pathman add ~/.local/bin/dart-sass
    }

    pkg_get_current_version() {
        echo $(dart-sass --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)
    }

}

__init_dart-sass
