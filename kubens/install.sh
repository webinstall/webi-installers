#!/bin/sh
set -e
set -u

__init_kubens() {

    ###################
    # Install kubens #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="kubens"

    pkg_dst_cmd="$HOME/.local/bin/kubens"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/kubens-v$WEBI_VERSION/bin/kubens"
    pkg_src_dir="$HOME/.local/opt/kubens-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # e.g. ~/.local/opt/kubens-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./kubens-*/kubens ~/.local/opt/kubens-v0.99.9/bin/kubens
        mv kubens "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'kubens' has no version parameter
        echo
    }

}

__init_kubens
