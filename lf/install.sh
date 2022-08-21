#!/bin/sh

__init_lf() {
    set -e
    set -u

    ##############
    # Install lf #
    ##############

    # Every package should define these 6 variables
    pkg_cmd_name="lf"

    pkg_dst_cmd="$HOME/.local/bin/lf"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/lf-v$WEBI_VERSION/bin/lf"
    pkg_src_dir="$HOME/.local/opt/lf-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    pkg_install() {
        # $HOME/.local/opt/lf-v0.21.0/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./lf "$HOME/.local/opt/lf-v0.21.0/bin/lf"
        mv ./lf "$pkg_src_cmd"

        # chmod a+x "$HOME/.local/opt/lf-v0.21.0/bin/lf"
        chmod a+x "$pkg_src_cmd"
    }

    pkg_get_current_version() {
        # 'lf --version' has output in this format:
        #       r21
        # This treats it as a minor version number:
        #       0.21.0
        echo "0.$(lf --version 2> /dev/null | head -n 1 | cut -d' ' -f1 | sed 's:^r::').0"
    }

}

__init_lf
