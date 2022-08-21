#!/bin/sh

__init_sclient() {
    set -e
    set -u

    ###################
    # Install sclient #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="sclient"

    pkg_dst_cmd="$HOME/.local/bin/sclient"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sclient-v$WEBI_VERSION/bin/sclient"
    pkg_src_dir="$HOME/.local/opt/sclient-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/sclient-v1.3.3/bin
        mkdir -p "$pkg_src_bin"

        # mv ./sclient* "$HOME/.local/opt/sclient-v1.3.3/bin/sclient"
        mv ./"$pkg_cmd_name"* "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/sclient-v1.3.3/bin/sclient"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'sclient version' has output in this format:
        #       sclient 1.3.3 (455db50) 2020-12-02T22:05:35Z
        # This trims it down to just the version number:
        #       1.3.3
        sclient --version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }

}

__init_sclient
