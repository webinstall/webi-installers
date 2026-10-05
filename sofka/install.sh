#!/bin/sh
set -e
set -u

__init_sofka() {

    ###################
    # Install sofka   #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="sofka"

    pkg_dst_cmd="$HOME/.local/bin/sofka"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/sofka-v$WEBI_VERSION/bin/sofka"
    pkg_src_dir="$HOME/.local/opt/sofka-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/sofka-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./sofka ~/.local/opt/sofka-v0.99.9/bin/sofka
        mv ./sofka "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'sofka --version' has output in this format:
        #       sofka 0.29.9
        # This trims it down to just the version number:
        #       0.29.9
        sofka --version 2> /dev/null | head -n 1 | cut -d ' ' -f 2
    }

}

__init_sofka
