#!/bin/sh
set -e
set -u

__init_kubectx() {

    ###################
    # Install kubectx #
    ###################

    # Every package should define these 6 variables
    pkg_cmd_name="kubectx"

    pkg_dst_cmd="$HOME/.local/bin/kubectx"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/kubectx-v$WEBI_VERSION/bin/kubectx"
    pkg_src_dir="$HOME/.local/opt/kubectx-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # e.g. ~/.local/opt/kubectx-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./kubectx-*/kubectx ~/.local/opt/kubectx-v0.99.9/bin/kubectx
        mv kubectx "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'kubectx' has no version parameter
        echo
    }

}

__init_kubectx
