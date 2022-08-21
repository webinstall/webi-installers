#!/bin/sh
set -e
set -u

__init_comrak() {

    ##################
    # Install comrak #
    ##################

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'comrak --version' has output in this format:
        #       comrak 0.8.1
        # This trims it down to just the version number:
        #       0.8.1
        comrak --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    pkg_install() {
        # ~/.local/bin
        mkdir -p "$pkg_src_bin"

        # mv ./comrak* ~/.local/opt/comrak-v0.8.1/bin/comrak
        mv ./comrak* "$pkg_src_cmd"

        # chmod a+x ~/.local/opt/comrak-v0.8.1/bin/comrak
        chmod a+x "$pkg_src_cmd"
    }

    pkg_post_install() {
        # create the xdg directories (i.e. ~/.config/comrak)
        "$pkg_src_cmd" --version > /dev/null
    }
}

__init_comrak
