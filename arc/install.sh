#!/bin/sh
set -e
set -u

__init_arc() {

    ####################
    # Install archiver #
    ####################

    # Every package should define these 6 variables
    pkg_cmd_name="arc"

    pkg_dst_cmd="$HOME/.local/bin/arc"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/archiver-v$WEBI_VERSION/bin/arc"
    pkg_src_dir="$HOME/.local/opt/archiver-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/arc-v3.2.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./arc_* ~/.local/opt/arc-v3.2.0/bin/arc
        mv ./arc_* "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'arc version' has output in this format:
        #       arc v3.5.0 (25e050d) 2020-10-30T03:27:58Z
        # This trims it down to just the version number:
        #       3.5.0
        arc version 2> /dev/null | head -n 1 | cut -d' ' -f2 | sed 's:^v::'
    }
}

__init_arc
