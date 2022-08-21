#!/bin/sh
set -e
set -u

__init_curlie() {

    ##################
    # Install curlie #
    ##################

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'curlie --version' has output in this format:
        #       curlie 1.6.9 (2022-04-04T15:04:20Z)
        # This trims it down to just the version number:
        #       1.6.9
        curlie version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    pkg_install() {
        # $HOME/.local/xbin
        mkdir -p "$pkg_src_bin"

        # mv ./curlie* "$HOME/.local/opt/curlie-v1.3.1/bin/curlie"
        mv ./curlie* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/curlie-v1.3.1/bin/curlie"
        chmod a+x "$pkg_src_cmd"
    }
}

__init_curlie
