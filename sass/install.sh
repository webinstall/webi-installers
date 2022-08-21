#!/bin/sh

__init_sass() {
    set -e
    set -u

    ##################
    # Install sass #
    ##################

    pkg_cmd_name="sass"

    pkg_dst_cmd="$HOME/.local/bin/sass"
    pkg_dst="$pkg_dst_cmd"

    # no ./bin dir here because of how the macOS version is packaged
    pkg_src_cmd="$HOME/.local/opt/dart-sass-v$WEBI_VERSION/sass"
    pkg_src_dir="$HOME/.local/opt/dart-sass-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # moves everything, for macOS' sake
        mkdir -p "$pkg_src_dir"
        mv ./dart-sass/* "$pkg_src_dir"
    }

    pkg_get_current_version() {
        sass --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_sass
