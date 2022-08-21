#!/bin/sh
set -e
set -u

__init_xz() {

    ##############
    # Install xz #
    ##############

    # Every package should define these 6 variables
    pkg_cmd_name="xz"

    pkg_dst_cmd="$HOME/.local/bin/xz"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/xz-v$WEBI_VERSION/bin/xz"
    pkg_src_dir="$HOME/.local/opt/xz-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/xz-v5.2.5/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./xz-*/{xz,xzdec} ~/.local/opt/xz-v5.2.5/bin/
        mv ./xz-*/xz* "$(dirname "$pkg_src_cmd")"
        ln -s xz "$(dirname "$pkg_src_cmd")/unxz"
    }

    pkg_post_install() {
        # supplements webi_link
        ln -s xz "$(dirname "$pkg_dst_cmd")/unxz"

        webi_post_install
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'xz --version' has output in this format:
        #       xz (XZ Utils) 5.2.5
        #       liblzma 5.2.5
        # This trims it down to just the version number:
        #       5.2.5
        xz --version 2> /dev/null | head -n 1 | cut -d ' ' -f 4
    }
}

__init_xz
