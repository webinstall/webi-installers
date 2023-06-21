#!/bin/sh
set -e
set -u

__init_ambient() {

    ##################
    # Install ambient #
    ##################

    WEBI_SINGLE=true

    pkg_get_current_version() {
        # 'ambient --version' has output in this format:
        #       ambient 0.8.1
        # This trims it down to just the version number:
        #       0.8.1
        ambient --version 2> /dev/null | head -n 1 | cut -d' ' -f 2
    }

    pkg_install() {
        # ~/.local/bin
        mkdir -p "$pkg_src_bin"

        # mv ./ambient* ~/.local/opt/ambient-v0.8.1/bin/ambient
        mv ./ambient* "$pkg_src_cmd"

        # chmod a+x ~/.local/opt/ambient-v0.8.1/bin/ambient
        chmod a+x "$pkg_src_cmd"
    }

    pkg_post_install() {
        # create the xdg directories (i.e. ~/.config/ambient)
        "$pkg_src_cmd" --version > /dev/null
    }
}

__init_ambient
