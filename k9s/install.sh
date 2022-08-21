#!/bin/sh
set -e
set -u

__init_k9s() {

    ##################
    # Install k9s #
    ##################

    # Every package should define these 6 variables
    pkg_cmd_name="k9s"

    pkg_dst_cmd="$HOME/.local/bin/k9s"
    pkg_dst="$pkg_dst_cmd"

    pkg_src_cmd="$HOME/.local/opt/k9s-v$WEBI_VERSION/bin/k9s"
    pkg_src_dir="$HOME/.local/opt/k9s-v$WEBI_VERSION"
    pkg_src="$pkg_src_cmd"

    # pkg_install must be defined by every package
    pkg_install() {
        # ~/.local/opt/k9s-v0.99.9/bin
        mkdir -p "$(dirname "$pkg_src_cmd")"

        # mv ./k9s-*/k9s ~/.local/opt/k9s-v0.99.9/bin/k9s
        mv k9s "$pkg_src_cmd"
    }

    # pkg_get_current_version is recommended, but (soon) not required
    pkg_get_current_version() {
        # 'k9s version' has output in this format:

        # Version:    v0.24.2
        # Commit:     f929114ae4679c89ca06b2833d8a0fca5f1ec69d
        # Date:       2020-12-04T17:42:10Z

        # This trims it down to just the version number:
        # 0.24.2
        k9s version 2> /dev/null | grep Version: | cut -d 'v' -f 2
    }

}

__init_k9s
