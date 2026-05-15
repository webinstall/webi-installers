#!/bin/sh
__init_btop() {
    set -e
    set -u

    ################
    # Install btop #
    ################

    # Every package should define these 6 variables
    pkg_cmd_name="btop"

    pkg_dst_cmd="$HOME/.local/bin/btop"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/btop-v$WEBI_VERSION/bin/btop"
    pkg_src_dir="$HOME/.local/opt/btop-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/btop-v1.4.6/bin
        mkdir -p "$(dirname "${pkg_src_cmd}")"

        # mv ./btop-*/btop ~/.local/opt/btop-v1.4.6/bin/btop
        mv ././btop/bin/btop "${pkg_src_cmd}"
    }

    # pkg_get_current_version is recommended, but not required
    pkg_get_current_version() {
        # 'btop --version' has output in this format:
        #       btop 1.4.6 (rev abcdef0123)
        # This trims it down to just the version number:
        #       1.4.6
        btop --version 2> /dev/null |
            head -n 1 |
            cut -d ' ' -f 2
    }

}

__init_btop
